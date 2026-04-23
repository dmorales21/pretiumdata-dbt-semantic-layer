# Parcl Labs Rent: Correct Source for IC (and Rent Metrics)

**Purpose:** IC and other rent metrics must use **Housing Event Prices** (median new rental listings), not the empty **RENT_LISTINGS** source.

## Right vs wrong source

| Use | Source | Metric / table | Status |
|-----|--------|----------------|--------|
| **Right** (IC, comps, rent metrics) | **PARCLLABS_HOUSING_EVENT_PRICES** → factized into **HOUSING_HOU_PRICING_ALL_TS** | `PARCLLABS_MEDIAN_RENT_NEW_LISTINGS` (ZIP × date) | ✅ Data present (e.g. 1,588 rows, 656 ZIPs, 6 months per PARCL_LABS_COMPS_READINESS_COMPLETE.md) |
| **Wrong** (currently empty) | SOURCE **RENT_LISTINGS** → cleaned_parcllabs_rent_listings → fact_parcllabs_rent_listings | `PARCLLABS_MEDIAN_RENT_LISTING` | ❌ RENT_LISTINGS and downstream are **empty** (0 rows) |

## Data flow (correct)

1. **CLEANED:** `TRANSFORM_PROD.CLEANED.PARCLLABS_HOUSING_EVENT_PRICES`  
   - Columns: `PRICE_NEW_RENTAL_LISTINGS`, `PSQF_NEW_RENTAL_LISTINGS`, geography (PARCL_ID → ZIP), `DATE_REFERENCE`.
2. **Factization script:** Populates `TRANSFORM_PROD.FACT.HOUSING_HOU_PRICING_ALL_TS` with:
   - `metric_id = 'PARCLLABS_MEDIAN_RENT_NEW_LISTINGS'` (and optionally `PARCLLABS_MEDIAN_RENT_PSQF_NEW_LISTINGS`).
3. **IC (and other consumers):** Read Parcl median rent from that fact table (or a dbt view over it), not from `fact_parcllabs_rent_listings`.

## IC wiring (after fix)

- **ic_features_county** and **ic_features_cbsa** use **fact_parcllabs_rent_event_prices**, a view that selects from `source('fact', 'housing_hou_pricing_all_ts')` filtered by `metric_id = 'PARCLLABS_MEDIAN_RENT_NEW_LISTINGS'`, so `housing_parcl_median_rent` is filled from Housing Event Prices.
- **fact_parcllabs_rent_listings** remains the path for RENT_LISTINGS; when/if that source is populated, it can be used elsewhere or merged with event-prices rent.

## References

- PARCL_LABS_DATA_DISCOVERY.md — PARCLLABS_HOUSING_EVENT_PRICES (72k+ rows), PRICE_NEW_RENTAL_LISTINGS.
- PARCL_LABS_COMPS_READINESS_PLAN.md — Factize PRICE_NEW_RENTAL_LISTINGS → PARCLLABS_MEDIAN_RENT_NEW_LISTINGS into HOUSING_HOU_PRICING_ALL_TS.
- PARCL_LABS_COMPS_READINESS_COMPLETE.md — 1,588 rows, 656 ZIPs, 6 months (2025-06-30 to 2025-11-30).
