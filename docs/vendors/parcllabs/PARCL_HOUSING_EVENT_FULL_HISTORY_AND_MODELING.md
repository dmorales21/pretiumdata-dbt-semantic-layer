# Parcl Labs Housing Event Data (Full History) and Modeling Use

**Purpose:** Explain how the **historical plus live** Parcl Labs housing-event datasets support **property**, **rent**, and **value** modeling in the Pretium pipeline, and how they relate to canonical facts and IC.

**Scope:** The three union stacks:

| Layer | Objects |
|--------|---------|
| Cleaned (tables) | `PARCLLABS_HOUSING_EVENT_COUNTS`, `PARCLLABS_HOUSING_EVENT_PRICES`, `PARCLLABS_PRICE_CHANGES` |
| Fact (wide tables) | `FACT_PARCLLABS_HOUSING_EVENT_COUNTS`, `FACT_PARCLLABS_HOUSING_EVENT_PRICES`, `FACT_PARCLLABS_PRICE_CHANGES` |

dbt models: `parcllabs_housing_event_*`, `parcllabs_price_changes`, and `fact_parcllabs_housing_event_*`, `fact_parcllabs_price_changes`. Build order: cleaned first, then facts (see `./scripts/run_parcllabs_housing_event_union.sh`).

---

## Grain and geography (read this first)

- **Natural grain:** Parcl **market** identifier `id_parcl` (numeric from Parcl) × `date_reference` (monthly), and for price changes also **`property_type`**.
- This is **not** property-level grain. It is **market / segment** time series (similar in spirit to many vendor “metro or market panel” feeds).
- **Joining to ZIP / CBSA / county** for models that use canonical `geo_id` requires a **crosswalk from Parcl market id to geography**. That crosswalk is not fully standardized in dbt today; some legacy paths use ZIP-as-`PARCL_ID` proxies (e.g. absorption bridge). Until a single ref model maps `id_parcl` → ZIP (or CBSA), treat these tables as **Parcl-market-indexed panels** when building features.

Implication for **property** modeling: Cherre/MLS/H3 engines stay **property-grain**; Parcl housing events contribute **market context** (rent level, turnover, listing pressure) once aligned to the property’s geography via the crosswalk.

---

## Rent modeling

**Primary signals (from `HOUSING_EVENT_PRICES` union):**

- **`price_new_rental_listings`** — median asking rent on **new rental listings** for that market-month. This is the core **market rent level** signal for single-family / broad rental product where Parcl defines the market.
- **`psqf_new_rental_listings`** — rent per square foot on the same basis; supports **normalization by size** and cross-market comparison.
- Related for-sale legs on the same row (`price_new_listings_for_sale`, `psqf_*`, acquisitions/dispositions) support **rent vs buy** context when combined with other data.

**Demand / flow (from `HOUSING_EVENT_COUNTS` union):**

- **`new_rental_listings`** — flow of new rental supply hitting the market.
- Together with sales and for-sale new listings, this helps characterize **rental vs ownership listing mix** and **market activity** (not a direct “occupancy” measure).

**Listing dynamics (from `PRICE_CHANGES` union):**

- Counts and shares of listings with price changes/drops, median days between changes, median pct change — useful for **rent market friction**, **repricing behavior**, and **“heat”** proxies at market-month × property_type grain.

**How this connects to IC and canonical pricing today**

- IC and several rent metrics are designed to consume Parcl **median rent from housing event prices** after it is represented in **`HOUSING_HOU_PRICING_ALL_TS`** as `PARCLLABS_MEDIAN_RENT_NEW_LISTINGS` (ZIP × date), not from the empty RENT_LISTINGS path. See [PARCL_RENT_SOURCE_FOR_IC.md](PARCL_RENT_SOURCE_FOR_IC.md) and [PARCL_LABS_COMPS_READINESS_PLAN.md](PARCL_LABS_COMPS_READINESS_PLAN.md).
- The **wide fact tables** (`FACT_PARCLLABS_HOUSING_EVENT_*`) preserve **full history** for analytics and future dbt-native factization; **backfilling** `HOUSING_HOU_PRICING_ALL_TS` from 2023 onward is a separate step (script or incremental dbt model) that maps `id_parcl` → `geo_id` and unpivots to long format.
- **`fact_parcllabs_rent_event_prices`** remains a **narrow view** on `housing_hou_pricing_all_ts` for one metric until that table is fully backfilled from the union.

**Rent model / forecast use cases**

- **Calibration:** Long history improves **seasonality and trend** estimation for market-level rent indices.
- **Features:** Month-over-month or year-over-year changes in median rent, new rental listings, and price-change metrics.
- **QA:** Compare Parcl market rent to ZORI, Markerr, or internal portfolio rent where geographies align.

---

## Value modeling (for-sale / asset value context)

**From `HOUSING_EVENT_PRICES`:**

- Median prices and PPSF for **new listings for sale**, **sales (acquisitions)**, and **dispositions** (recent leg) anchor **market clearing levels** and **trading activity** at Parcl market grain.

**From `HOUSING_EVENT_COUNTS`:**

- **`sales`**, **`new_listings_for_sale`**, **`transfers`** support **volume**, **liquidity**, and **gross flow** narratives (again at market-month grain).

**From `PRICE_CHANGES`:**

- **Property-type** slices (e.g. single-family vs condo) support **segmented** repricing and inventory stress signals relevant to **exit pricing** and **market risk**.

**How this touches “value” in the stack**

- **Automated valuation / H3 / calculator** pipelines that are **property-grain** still rely primarily on MLS/Cherre comparables; Parcl contributes **macro market conditions** (level and volatility of prices and flows) once joined to the property’s market or geography.
- **Cap-rate and yield** style reasoning can combine Parcl **rent level** (housing event prices) with external or internal **value** or **price** measures at aligned geography.

---

## Property modeling (inventory, progress, foot print)

- **Listing-level Parcl** (e.g. comps, rent listings) is a different lineage from these three **aggregated market** tables.
- **Progress / footprint / property intelligence** use cases that need “what is Parcl saying about this ZIP or market this month?” can draw on the **wide facts** after **geo alignment**.
- **Days on market** and similar **inventory** metrics in governance docs sometimes reference Parcl DOM via comps or other feeds; the **housing event counts** feed emphasizes **counts and flows**, not DOM — check metric dictionary for the exact `metric_id` source.

---

## Segmentation and absorption

- Documentation for segmentation and absorption often references **canonical inventory / DOM** unions (e.g. Redfin, Cherre MLS, Realtor, Parcl DOM where loaded). See `docs/methodologies/absorption_segmentation/SEGMENTATION_ANALYTICS_METHODOLOGY.md`.
- Parcl **sales / new listings / new rental listings** from the event-counts union can reinforce **absorption-style** stories (flow relative to stock) when definitions match the segment; wiring is **not automatic** — explicit feature models should join on geography and time.

---

## Summary table

| Modeling theme | Main Parcl columns / objects | Role |
|----------------|------------------------------|------|
| **Rent level** | `price_new_rental_listings`, `psqf_new_rental_listings` in prices union | Market-month median rent; feed IC via `HOUSING_HOU_PRICING_ALL_TS` after factization + geo map |
| **Rent demand / supply flow** | `new_rental_listings`, `new_listings_for_sale`, `sales` in counts union | Activity and mix |
| **Rent / list market stress** | Price change metrics × `property_type` | Repricing, friction |
| **Value / for-sale** | Sale and for-sale price columns, counts | Market clearing and liquidity context |
| **Property-level AVM** | Indirect | Use as **market prior** or feature after `id_parcl` → geo join |

---

## Operational notes

- **Rebuild:** `./scripts/run_parcllabs_housing_event_union.sh run-cleaned` then `run-facts-events` (or `all` if you also refresh legacy Parcl facts).
- **Verification:** `./scripts/run_parcllabs_housing_event_union.sh verify` (Snowflake row counts and fact vs cleaned checks).

---

## Related docs

- [PARCL_RENT_SOURCE_FOR_IC.md](PARCL_RENT_SOURCE_FOR_IC.md) — Housing event prices vs RENT_LISTINGS for IC.
- [PARCL_LABS_COMPS_READINESS_PLAN.md](PARCL_LABS_COMPS_READINESS_PLAN.md) — Factization into `HOUSING_HOU_PRICING_ALL_TS`.
- [IC_MISSING_FEATURES_BUILD_GUIDE.md](../../governance/IC_MISSING_FEATURES_BUILD_GUIDE.md) — `housing_parcl_median_rent` lineage.
- [PARCL_SOURCE_FACTIZATION.md](../../governance/PARCL_SOURCE_FACTIZATION.md) — Broader Parcl fact patterns.
