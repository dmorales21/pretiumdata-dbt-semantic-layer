# Progress Offerings Time Series Table Documentation

**Table**: `ANALYTICS_PROD.MODELED.PROGRESS_OFFERINGS_TIMESERIES_CBSA`  
**Purpose**: Materialized table with Progress offering-relevant metrics in time series format, including Realtor.com and Redfin supply baselines and Fund 7 composite scoring  
**Coverage**: All 939 CBSAs from `ANALYTICS_PROD.MARKETS.MAP_CBSA`  
**Last Updated**: 2026-01-27

---

## Table Overview

This table provides a comprehensive view of Progress offering-relevant metrics for all CBSAs, including:

- **Baseline Metrics**: Housing stock, employment, wages (current snapshot)
- **Historical Time Series**: 12 months of supply/demand metrics (pivoted wide)
- **Forecasts**: 24-month forward projections from Oxford Economics AMREG
- **Supply Baselines**: Realtor.com and Redfin metrics (12 months historical)
- **Fund 7 Composite Scoring**: Market selection methodology with z-score normalization

### Key Design Decisions

1. **Nullable Schema**: All columns are nullable except `ID_CBSA` to prevent NOT NULL constraint violations during refresh
2. **Time Series Format**: Historical metrics are pivoted wide (M0 = current month, M1 = 1 month ago, etc.)
3. **Data Quality Tiers**: Z-scores are normalized within `DATA_QUALITY_TIER` to ensure fair comparisons
4. **Atomic Refresh**: Uses temp table pattern to ensure all-or-nothing refresh

---

## Schema Reference

### Primary Key
- `ID_CBSA` (STRING, NOT NULL): CBSA code (5-digit), primary key

### Baseline Metrics (Current Snapshot)
- `TOTAL_HOUSING_UNITS` (NUMBER): Total housing units in CBSA
- `TOTAL_HOUSEHOLDS` (NUMBER): Total households in CBSA
- `RENTER_OCCUPIED` (NUMBER): Renter-occupied housing units (critical for Progress offerings)
- `OWNER_OCCUPIED` (NUMBER): Owner-occupied housing units
- `CPS_MEDIAN_WEEKLY_WAGE` (NUMBER): Median weekly wage from Current Population Survey
- `CPS_EMPLOYMENT` (NUMBER): Employment count from CPS
- `CPS_UNEMPLOYMENT_RATE` (NUMBER): Unemployment rate from CPS
- `CPS_POPULATION` (NUMBER): Population from CPS
- `CPS_LABOR_FORCE` (NUMBER): Labor force count from CPS

### Historical Time Series (12 months, pivoted wide)

#### PARCL Metrics
- `PARCL_MOS_M0` through `PARCL_MOS_M11`: PARCL months of supply (M0 = current month)
- `PARCL_ABSORPTION_ACTIVE_M0` through `PARCL_ABSORPTION_ACTIVE_M11`: PARCL active listing absorption rate
- `PARCL_ABSORPTION_NEW_M0` through `PARCL_ABSORPTION_NEW_M11`: PARCL new listing absorption rate

#### Realtor.com Metrics
- `REALTOR_ACTIVE_LISTINGS_M0` through `REALTOR_ACTIVE_LISTINGS_M11`: Active listing count
- `REALTOR_NEW_LISTINGS_M0` through `REALTOR_NEW_LISTINGS_M11`: New listing count
- `REALTOR_DOM_M0` through `REALTOR_DOM_M11`: Median days on market
- `REALTOR_MEDIAN_PRICE_M0` through `REALTOR_MEDIAN_PRICE_M11`: Median listing price
- `REALTOR_MONTHS_OF_SUPPLY_M0` through `REALTOR_MONTHS_OF_SUPPLY_M11`: Calculated months of supply

#### Redfin Metrics
- `REDFIN_INVENTORY_M0` through `REDFIN_INVENTORY_M11`: Inventory count
- `REDFIN_MONTHS_OF_SUPPLY_M0` through `REDFIN_MONTHS_OF_SUPPLY_M11`: Months of supply
- `REDFIN_HOMES_SOLD_M0` through `REDFIN_HOMES_SOLD_M11`: Homes sold count
- `REDFIN_SALE_TO_LIST_RATIO_M0` through `REDFIN_SALE_TO_LIST_RATIO_M11`: Sale-to-list ratio
- `REDFIN_ABSORPTION_RATE_M0` through `REDFIN_ABSORPTION_RATE_M11`: Absorption rate
- `REDFIN_DOM_M0` through `REDFIN_DOM_M11`: Median days on market

#### Employment/Wage Growth
- `EMP_GROWTH_M0` through `EMP_GROWTH_M11`: Employment growth YoY
- `WAGE_GROWTH_M0` through `WAGE_GROWTH_M11`: Wage growth YoY

#### Rent/Price Growth
- `RENT_GROWTH_M0` through `RENT_GROWTH_M11`: Rent growth YoY
- `PRICE_GROWTH_M0` through `PRICE_GROWTH_M11`: Price growth YoY

### Forecasts (24-month forward)
- `R_FWD_24M` (NUMBER): Forward rent forecast (Oxford Economics AMREG)
- `P_FWD_24M` (NUMBER): Forward price forecast (Oxford Economics AMREG)
- `G_R_FWD_24M` (NUMBER): Forward rent growth forecast (Oxford Economics AMREG)
- `Y_FWD_24M` (NUMBER): Forward yield forecast (Oxford Economics AMREG)

### Fund 7 Composite Scoring

#### Input Metrics
- `GROSS_YIELD_PCT` (NUMBER): Annual rent / purchase price
- `OPEX_RATIO` (NUMBER): Operating expense ratio
- `NET_YIELD_PCT` (NUMBER): Gross yield * (1 - OPEX_RATIO)
- `PORTFOLIO_PROPERTY_COUNT` (NUMBER): Portfolio property count (for operational accelerator)

#### Scoring Components (z-score normalized within DATA_QUALITY_TIER)
- `TIMING_2Y_SCORE` (NUMBER): 60% net yield + 30% rent growth - 10% price penalty
- `CONVERGENCE_2Y_SCORE` (NUMBER): Rent-price convergence (positive = rent catching up)
- `EXPECTED_RETURN_2Y` (NUMBER): TIMING_2Y_SCORE + CONVERGENCE_2Y_SCORE
- `SUPPLY_RISK_2Y` (NUMBER): Supply risk penalty (higher = more risk)
- `DEMAND_CUSHION_2Y` (NUMBER): Employment + wage growth - unemployment
- `RISK_PENALTY_2Y` (NUMBER): SUPPLY_RISK_2Y * 1.0 + adjustments
- `NET_SCORE_2Y` (NUMBER): EXPECTED_RETURN_2Y - RISK_PENALTY_2Y
- `OPERATIONAL_ACCELERATOR` (NUMBER): Portfolio presence bonus (up to 0.15)
- `FINAL_SCORE_2Y` (NUMBER): NET_SCORE_2Y + OPERATIONAL_ACCELERATOR
- `DATA_QUALITY_TIER` (STRING): Tier for z-score normalization (TIER_1, TIER_2, TIER_3, TIER_4)
- `MARKET_RANK_2Y` (NUMBER): Rank by FINAL_SCORE_2Y (1 = highest score)

### Metadata
- `AS_OF_DATE` (DATE): Latest DATE_REFERENCE from source tables
- `REFRESHED_AT` (TIMESTAMP_NTZ): Timestamp when table was last refreshed
- `VALIDATION_STATUS` (STRING): 'PASS', 'FAIL', or 'PENDING'
- `SOURCE_MAX_DATES` (VARIANT): JSON with max dates from each source table

---

## Data Sources

### Baseline Metrics
- **Housing Stock**: `ANALYTICS_PROD.MARKETS.V_CBSA_STRATIFICATION`
- **Employment/Wages**: `ANALYTICS_PROD.FEATURES.BLS_CPS_CBSA`

### Historical Time Series
- **PARCL Metrics**: `ANALYTICS_PROD.FEATURES.FEATURE_MARKET_SPOT_CBSA`
- **Realtor.com Metrics**: `TRANSFORM_PROD.JOINED.FACT_REALTOR_CBSA_METRICS`
- **Redfin Metrics**: `ANALYTICS_PROD.FEATURES.REDFIN_ZIP_FEATURES_WIDE` (aggregated from ZIP to CBSA via `TRANSFORM_PROD.REF.H3_XWALK_6810_CANON`)
- **Employment/Wage Growth**: `ANALYTICS_PROD.FEATURES.FEATURE_MARKET_SPOT_CBSA`
- **Rent/Price Growth**: `ANALYTICS_PROD.FEATURES.FEATURE_MARKET_SPOT_CBSA`

### Forecasts
- **Oxford Economics AMREG**: `ANALYTICS_PROD.FEATURES.FEATURE_MARKET_OUTLOOK_CBSA`

### Fund 7 Composite Scoring
- **Net Yield, OpEx Ratio, Portfolio Presence**: `ANALYTICS_PROD.MODELED.FUND_7_CURRENT_OUTLOOK_OPEX_ADJUSTED`

---

## Fund 7 Composite Scoring Methodology

The Fund 7 composite scoring methodology mirrors `FUND_7_CURRENT_OUTLOOK_OPEX_ADJUSTED` and includes:

### 1. Net Yield Durability
- **Gross Yield**: Annual rent / purchase price
- **OpEx Ratio**: Operating expense ratio (market-specific)
- **Net Yield**: Gross yield * (1 - OPEX_RATIO)

### 2. Scoring Components

#### TIMING_2Y_SCORE
- **60% Net Yield**: Z-score normalized within `DATA_QUALITY_TIER`
- **30% Forward Rent Growth**: Z-score normalized within `DATA_QUALITY_TIER`
- **10% Forward Price Penalty**: Z-score normalized within `DATA_QUALITY_TIER` (subtracted)

#### CONVERGENCE_2Y_SCORE
- **Current Convergence**: (Rent Growth - Price Growth) z-score (clamped to [-3, +3])
- **Forward Convergence**: (R_FWD - P_FWD) z-score (clamped to [-3, +3])
- **Positive = Rent catching up to price**

#### SUPPLY_RISK_2Y
- **50% PARCL Months of Supply**: Z-score normalized (higher = more risk)
- **50% PARCL Absorption New**: Z-score normalized (inverted, lower = more risk)
- **30% PARCL Absorption Active**: Z-score normalized (inverted, lower = more risk)
- **All z-scores clamped to [-3, +3]**

#### DEMAND_CUSHION_2Y
- **45% Employment Growth**: Z-score normalized (positive = good)
- **45% Wage Growth**: Z-score normalized (positive = good)
- **10% Unemployment Rate**: Z-score normalized (inverted, lower = good)
- **All z-scores clamped to [-3, +3]**

### 3. Final Score Calculation

```
EXPECTED_RETURN_2Y = TIMING_2Y_SCORE + CONVERGENCE_2Y_SCORE
RISK_PENALTY_2Y = SUPPLY_RISK_2Y * 1.0 + adjustments
NET_SCORE_2Y = EXPECTED_RETURN_2Y - RISK_PENALTY_2Y
OPERATIONAL_ACCELERATOR = min(PORTFOLIO_PROPERTY_COUNT * 0.15 / 100.0, ABS(NET_SCORE_2Y) * 0.15)
FINAL_SCORE_2Y = NET_SCORE_2Y + OPERATIONAL_ACCELERATOR
MARKET_RANK_2Y = DENSE_RANK() OVER (ORDER BY FINAL_SCORE_2Y DESC)
```

### 4. Data Quality Tiers

- **TIER_1**: All core metrics available (PARCL, Redfin/Realtor, Employment)
- **TIER_2**: Missing PARCL but has Redfin/Realtor and Employment
- **TIER_3**: Missing supply metrics but has Employment
- **TIER_4**: Minimal data

Z-scores are normalized **within each tier** to ensure fair comparisons.

---

## Refresh Process

### Prerequisites

1. **Snowflake Access**: `DATA_ENGINEER` role with access to `ANALYTICS_PROD.MODELED` schema
2. **Source Tables**: All source tables must be up-to-date
3. **Python Environment**: Python 3.9+ with `snowflake-connector-python`, `boto3` installed

### Refresh Script

**File**: `scripts/refresh_progress_offerings_timeseries.py`

**Usage**:
```bash
python scripts/refresh_progress_offerings_timeseries.py
```

### Refresh Steps

1. **Validation**: Validates data recency for all source tables
   - Checks `MAX(DATE_REFERENCE)` for each source
   - Ensures all 939 CBSAs are present
   - Validates source alignment (no drift beyond tolerance)

2. **Data Retrieval**: Retrieves data from all sources
   - Baseline metrics (housing stock, employment)
   - Historical time series (12 months, pivoted wide)
   - Realtor.com time series (unpivoted format)
   - Redfin time series (ZIP aggregated to CBSA)
   - Forecasts (Oxford Economics AMREG)
   - Fund 7 composite scoring inputs

3. **Composite Scoring**: Calculates Fund 7 composite scores
   - Assigns `DATA_QUALITY_TIER` based on data availability
   - Calculates z-scores within each tier
   - Clamps z-scores to [-3, +3]
   - Calculates final scores and rankings

4. **Atomic Refresh**: Uses temp table pattern
   - Creates temp table with refreshed data
   - Validates temp table (row count, NULL checks, score ranges)
   - Swaps temp table with production table (atomic operation)

5. **Post-Refresh Validation**: Validates refreshed table
   - Row count = 939
   - `ID_CBSA` is never NULL
   - `AS_OF_DATE` is not NULL
   - At least 50% of CBSAs have non-NULL baseline metrics
   - Composite scores calculated for all CBSAs
   - Realtor.com and Redfin supply baselines available for at least 50% of CBSAs
   - Scoring methodology matches Fund 7 (z-scores normalized within `DATA_QUALITY_TIER`)

### Refresh Frequency

- **Recommended**: Weekly (after source tables are refreshed)
- **Minimum**: Monthly (to capture latest forecasts and supply baselines)

---

## Usage Examples

### Query Top 20 Markets by FINAL_SCORE_2Y

```sql
SELECT 
    ID_CBSA,
    MARKET_RANK_2Y,
    FINAL_SCORE_2Y,
    NET_SCORE_2Y,
    TIMING_2Y_SCORE,
    CONVERGENCE_2Y_SCORE,
    SUPPLY_RISK_2Y,
    DEMAND_CUSHION_2Y,
    DATA_QUALITY_TIER,
    AS_OF_DATE
FROM ANALYTICS_PROD.MODELED.PROGRESS_OFFERINGS_TIMESERIES_CBSA
WHERE AS_OF_DATE = (SELECT MAX(AS_OF_DATE) FROM ANALYTICS_PROD.MODELED.PROGRESS_OFFERINGS_TIMESERIES_CBSA)
ORDER BY MARKET_RANK_2Y
LIMIT 20;
```

### Query Supply Baselines for Specific CBSA

```sql
SELECT 
    ID_CBSA,
    -- Realtor.com (current month)
    REALTOR_ACTIVE_LISTINGS_M0,
    REALTOR_NEW_LISTINGS_M0,
    REALTOR_MONTHS_OF_SUPPLY_M0,
    REALTOR_DOM_M0,
    -- Redfin (current month)
    REDFIN_INVENTORY_M0,
    REDFIN_MONTHS_OF_SUPPLY_M0,
    REDFIN_HOMES_SOLD_M0,
    REDFIN_ABSORPTION_RATE_M0,
    -- PARCL (current month)
    PARCL_MOS_M0,
    PARCL_ABSORPTION_ACTIVE_M0,
    PARCL_ABSORPTION_NEW_M0
FROM ANALYTICS_PROD.MODELED.PROGRESS_OFFERINGS_TIMESERIES_CBSA
WHERE ID_CBSA = '31080'  -- Los Angeles-Long Beach-Anaheim, CA
  AND AS_OF_DATE = (SELECT MAX(AS_OF_DATE) FROM ANALYTICS_PROD.MODELED.PROGRESS_OFFERINGS_TIMESERIES_CBSA);
```

### Query Time Series Trend for Supply Metrics

```sql
SELECT 
    ID_CBSA,
    -- Realtor.com months of supply trend (M0 = current, M11 = 11 months ago)
    REALTOR_MONTHS_OF_SUPPLY_M0,
    REALTOR_MONTHS_OF_SUPPLY_M1,
    REALTOR_MONTHS_OF_SUPPLY_M2,
    REALTOR_MONTHS_OF_SUPPLY_M3,
    -- Redfin months of supply trend
    REDFIN_MONTHS_OF_SUPPLY_M0,
    REDFIN_MONTHS_OF_SUPPLY_M1,
    REDFIN_MONTHS_OF_SUPPLY_M2,
    REDFIN_MONTHS_OF_SUPPLY_M3,
    -- PARCL months of supply trend
    PARCL_MOS_M0,
    PARCL_MOS_M1,
    PARCL_MOS_M2,
    PARCL_MOS_M3
FROM ANALYTICS_PROD.MODELED.PROGRESS_OFFERINGS_TIMESERIES_CBSA
WHERE ID_CBSA = '31080'  -- Los Angeles-Long Beach-Anaheim, CA
  AND AS_OF_DATE = (SELECT MAX(AS_OF_DATE) FROM ANALYTICS_PROD.MODELED.PROGRESS_OFFERINGS_TIMESERIES_CBSA);
```

### Query Markets by Data Quality Tier

```sql
SELECT 
    DATA_QUALITY_TIER,
    COUNT(*) AS MARKET_COUNT,
    AVG(FINAL_SCORE_2Y) AS AVG_FINAL_SCORE,
    MIN(FINAL_SCORE_2Y) AS MIN_FINAL_SCORE,
    MAX(FINAL_SCORE_2Y) AS MAX_FINAL_SCORE
FROM ANALYTICS_PROD.MODELED.PROGRESS_OFFERINGS_TIMESERIES_CBSA
WHERE AS_OF_DATE = (SELECT MAX(AS_OF_DATE) FROM ANALYTICS_PROD.MODELED.PROGRESS_OFFERINGS_TIMESERIES_CBSA)
GROUP BY DATA_QUALITY_TIER
ORDER BY DATA_QUALITY_TIER;
```

---

## Validation Checks

The refresh script performs the following validation checks:

### Pre-Refresh Validation
- ✅ Source table recency: All sources have `MAX(DATE_REFERENCE)` within tolerance
- ✅ Source alignment: All sources aligned to same `DATE_REFERENCE` (no drift)
- ✅ CBSA coverage: All 939 CBSAs from `MAP_CBSA` are present

### Post-Refresh Validation
- ✅ Row count: Exactly 939 rows
- ✅ `ID_CBSA` is never NULL
- ✅ `AS_OF_DATE` is not NULL
- ✅ Baseline metrics: At least 50% of CBSAs have non-NULL baseline metrics
- ✅ Composite scores: All CBSAs have calculated composite scores
- ✅ Supply baselines: At least 50% of CBSAs have Realtor.com or Redfin data
- ✅ Scoring methodology: Z-scores normalized within `DATA_QUALITY_TIER`

### Validation Failures

If validation fails:
1. **Check source tables**: Ensure all source tables are up-to-date
2. **Check data quality**: Review `SOURCE_MAX_DATES` JSON for date alignment
3. **Check logs**: Review refresh script output for specific error messages
4. **Re-run refresh**: Fix source issues and re-run refresh script

---

## Troubleshooting

### Issue: Table refresh fails with "NULL result in a non-nullable column"

**Solution**: This should not occur with the current nullable schema. If it does:
1. Check that `create_progress_offerings_timeseries_table.sql` was executed correctly
2. Verify all columns (except `ID_CBSA`) are nullable
3. Check refresh SQL for any hardcoded NOT NULL constraints

### Issue: Missing Realtor.com or Redfin data

**Solution**:
1. Check `TRANSFORM_PROD.JOINED.FACT_REALTOR_CBSA_METRICS` for latest data
2. Check `ANALYTICS_PROD.FEATURES.REDFIN_ZIP_FEATURES_WIDE` for latest data
3. Verify ZIP-to-CBSA crosswalk (`TRANSFORM_PROD.REF.H3_XWALK_6810_CANON`) is up-to-date
4. Review `SOURCE_MAX_DATES` JSON in table to see which sources are missing

### Issue: Composite scores seem incorrect

**Solution**:
1. Verify `DATA_QUALITY_TIER` assignment is correct
2. Check that z-scores are normalized within tier (not across all markets)
3. Verify z-scores are clamped to [-3, +3]
4. Review `FUND_7_CURRENT_OUTLOOK_OPEX_ADJUSTED` for comparison

### Issue: Refresh takes too long

**Solution**:
1. Check warehouse size (should use `AI_WH` or larger)
2. Review source table sizes (Redfin ZIP aggregation can be slow)
3. Consider materializing intermediate views if refresh is frequent

---

## Related Documentation

- **Fund 7 Market Selection**: `docs/modeling/20260107_fund73.rtf`
- **Fund 7 Table**: `sql/analytics/modeled/14_create_fund_7_table.sql`
- **Fund 7 View**: `sql/analytics/modeled/14_fund_7_current_outlook_opex_adjusted.sql`
- **Progress Offerings Data Sources**: `docs/OFFERING_MODELING_DEEP_RESEARCH.md`
- **Data Recency Strategy**: `docs/OFFERING_SPECIFIC_HOUSEHOLD_COUNTS_STRATEGY.md`

---

## Change Log

- **2026-01-27**: Initial table creation with Realtor.com and Redfin supply baselines and Fund 7 composite scoring

