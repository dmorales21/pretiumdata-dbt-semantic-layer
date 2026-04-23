# Parcl Labs Data Discovery for Progress Presentation Charts

**Date**: 2026-01-27  
**Purpose**: Document available Parcl Labs data in CLEANED tables and identify what needs to be factized

---

## Executive Summary

**Status**: ✅ **DATA EXISTS IN CLEANED** - But NOT in FACT tables

**Key Finding**: Parcl Labs ownership and pricing data exists in CLEANED tables but has NOT been factized to FACT tables. The chart generation script requires FACT table data, so factization is needed.

---

## Available Parcl Labs Tables in CLEANED

### ✅ Ownership Data (Available)

**Table**: `TRANSFORM_PROD.CLEANED.PARCLLABS_SF_HOUSING_STOCK_OWNERSHIP`
- **Rows**: 30,338
- **Geography**: ZIP level (1,400 distinct ZIPs)
- **Time Series**: 22 months (2024-03-01 to 2025-12-01)
- **Structure**: 
  - `ID_ZIP` (TEXT) - ZIP code
  - `DATE_REFERENCE` (DATE) - Monthly data
  - `COUNT_PORTFOLIO_2_TO_9` (NUMBER) - Units in 2-9 unit portfolios
  - `COUNT_PORTFOLIO_10_TO_99` (NUMBER) - Units in 10-99 unit portfolios
  - `COUNT_PORTFOLIO_100_TO_999` (NUMBER) - Units in 100-999 unit portfolios ⭐
  - `COUNT_PORTFOLIO_1000_PLUS` (NUMBER) - Units in 1000+ unit portfolios ⭐
  - `COUNT_ALL_PORTFOLIOS` (NUMBER) - All portfolio units ⭐
  - Percentage columns for each category

**Required for Charts**: 
- `COUNT_PORTFOLIO_100_TO_999` → `PARCLLABS_OWNERSHIP_PORTFOLIO_100_999_UNITS`
- `COUNT_PORTFOLIO_1000_PLUS` → `PARCLLABS_OWNERSHIP_PORTFOLIO_1000_PLUS_UNITS`
- `COUNT_ALL_PORTFOLIOS` → `PARCLLABS_OWNERSHIP_ALL_PORTFOLIO_UNITS`

**Issue**: Data is at ZIP level, needs aggregation to CBSA for charts

---

### ✅ Housing Stock Data (Available)

**Table**: `TRANSFORM_PROD.CLEANED.PARCLLABS_HOUSING_STOCK`
- **Rows**: 109,623
- **Geography**: PARCL_ID (needs mapping to ZIP/CBSA)
- **Time Series**: Monthly data
- **Structure**:
  - `PARCL_ID` (NUMBER) - Parcl Labs geography ID
  - `DATE_REFERENCE` (DATE)
  - `SF_UNITS` (NUMBER) - Single-family units ⭐
  - `TOWNHOUSE_UNITS` (NUMBER)
  - `CONDO_UNITS` (NUMBER)
  - `OTHER_UNITS` (NUMBER)
  - `TOTAL_UNITS` (NUMBER)

**Required for Charts**:
- `SF_UNITS` → `PARCLLABS_HOUSING_STOCK_SF_UNITS` (denominator for ownership percentages)

**Issue**: Needs mapping from PARCL_ID to ZIP/CBSA

---

### ✅ Pricing Data (Available)

**Table**: `TRANSFORM_PROD.CLEANED.PARCLLABS_HOUSING_EVENT_PRICES`
- **Rows**: 72,398
- **Time Series**: 7 months (2025-06-30 to 2025-12-31)
- **Pricing Columns**:
  - `PRICE_NEW_RENTAL_LISTINGS` - Rent prices for new listings ⭐
  - `PRICE_ACQUISITIONS` - Acquisition prices
  - `PRICE_DISPOSITIONS` - Disposition prices
  - `PRICE_NEW_LISTINGS_FOR_SALE` - Sale prices
  - `PSQF_NEW_RENTAL_LISTINGS` - Price per square foot for rentals

**Table**: `TRANSFORM_PROD.CLEANED.PARCLLABS_HOUSING_EVENT_PRICES_TALL`
- **Rows**: 196,988
- **Time Series**: 7 months (2025-06-30 to 2025-12-31)
- **Structure**: Tall format with `METRIC` and `VALUE` columns

**Note**: Pricing data is recent (last 7 months) and may not cover full 2018-2025 range needed for charts

---

### ❌ Missing: Rent History

**Table**: `TRANSFORM_PROD.CLEANED.PARCLLABS_RENT_HISTORY`
- **Status**: Does NOT exist
- **Expected**: Time series rent data by ZIP/CBSA
- **Alternative**: May exist in `PARCLLABS_HOUSING_EVENT_PRICES` with `PRICE_NEW_RENTAL_LISTINGS`

---

## FACT Table Status

### ❌ HOUSING_HOU_OWNERSHIP_ALL_TS
- **Status**: No Parcl Labs data found
- **Required METRIC_IDs**:
  - `PARCLLABS_OWNERSHIP_PORTFOLIO_100_999_UNITS`
  - `PARCLLABS_OWNERSHIP_PORTFOLIO_1000_PLUS_UNITS`
  - `PARCLLABS_OWNERSHIP_ALL_PORTFOLIO_UNITS`
  - `PARCLLABS_HOUSING_STOCK_SF_UNITS`

### ❌ HOUSING_HOU_PRICING_ALL_TS
- **Status**: No Parcl Labs data found
- **Required METRIC_IDs**: None currently (pricing charts use Zillow data)

---

## Required Factization Actions

### Priority 1: Factize Ownership Data

**Source**: `TRANSFORM_PROD.CLEANED.PARCLLABS_SF_HOUSING_STOCK_OWNERSHIP`

**Steps**:
1. Aggregate ZIP-level data to CBSA using ZIP→CBSA crosswalk
2. Map columns to METRIC_IDs:
   - `COUNT_PORTFOLIO_100_TO_999` → `PARCLLABS_OWNERSHIP_PORTFOLIO_100_999_UNITS`
   - `COUNT_PORTFOLIO_1000_PLUS` → `PARCLLABS_OWNERSHIP_PORTFOLIO_1000_PLUS_UNITS`
   - `COUNT_ALL_PORTFOLIOS` → `PARCLLABS_OWNERSHIP_ALL_PORTFOLIO_UNITS`
3. Insert into `HOUSING_HOU_OWNERSHIP_ALL_TS` with:
   - `GEO_LEVEL_CODE` = 'CBSA'
   - `DOMAIN` = 'HOUSING'
   - `TAXON` = 'HOU_OWNERSHIP'
   - `VENDOR_NAME` = 'PARCLLABS'

### Priority 2: Factize Housing Stock Data

**Source**: `TRANSFORM_PROD.CLEANED.PARCLLABS_HOUSING_STOCK`

**Steps**:
1. Map PARCL_ID to ZIP/CBSA using `PARCLLABS_MARKET` table
2. Aggregate to CBSA level
3. Map `SF_UNITS` → `PARCLLABS_HOUSING_STOCK_SF_UNITS`
4. Insert into `HOUSING_HOU_INVENTORY_ALL_TS` or `HOUSING_HOU_OWNERSHIP_ALL_TS`

### Priority 3: Factize Pricing Data (Optional)

**Source**: `TRANSFORM_PROD.CLEANED.PARCLLABS_HOUSING_EVENT_PRICES_TALL`

**Steps**:
1. Filter for rent-related metrics (`PRICE_NEW_RENTAL_LISTINGS`)
2. Aggregate to CBSA level
3. Insert into `HOUSING_HOU_PRICING_ALL_TS`

**Note**: Limited time series (7 months) may not be sufficient for charts

---

## Mapping Requirements

### ZIP → CBSA Mapping
- Use `TRANSFORM_PROD.REF.H3_XWALK_6810_CANON` or `TRANSFORM_PROD.REF.MAP_ZIP`
- Join on `ID_ZIP` to get `ID_CBSA`

### PARCL_ID → ZIP/CBSA Mapping
- Use `TRANSFORM_PROD.CLEANED.PARCLLABS_MARKET` table
- Join on `PARCL_ID` to get geography information

---

## Existing Factization Scripts

Found these scripts that may need to be executed or updated:

1. `sql/transform/fact/populate_fact_housing_hou_ownership_parcllabs.sql` - Ownership factization
2. `sql/transform/fact/populate_fact_housing_hou_inventory_parcllabs_housing_stock.sql` - Stock factization
3. `sql/transform/fact/populate_fact_housing_hou_pricing_parcllabs_rent.sql` - Pricing factization (references non-existent table)

---

## Next Steps

1. ✅ **Completed**: Discovered all Parcl Labs tables in CLEANED
2. ⏳ **Next**: Review/execute existing factization scripts
3. ⏳ **Next**: Create/update scripts to aggregate ZIP→CBSA
4. ⏳ **Next**: Verify data appears in FACT tables
5. ⏳ **Next**: Update chart generation script to use FACT data

---

**Last Updated**: 2026-01-27

