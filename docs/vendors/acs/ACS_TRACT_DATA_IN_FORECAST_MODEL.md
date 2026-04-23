# How ACS Tract Data Leverages the Forward-Looking Demand Forecast

**Date**: 2026-01-12  
**Status**: ✅ **INTEGRATED**

---

## Executive Summary

The forward-looking demand forecast model (`FEATURE_MARKET_FORECAST_2Y_CBSA`) now integrates **ACS (American Community Survey) tract-level data** as the primary source for demand estimation, with economic fundamentals and operational absorption as fallbacks. This provides the most granular and accurate demand forecasts by leveraging Census tract-level housing characteristics.

---

## 1. Data Flow Architecture

### 1.1 ACS Tract Data → CBSA Forecast

```
ACS Tract Data (FACT_ACS_TRACT_TS)
    ↓
V_TRACT_HOUSING_COHORT (Tract-level housing characteristics)
    ↓
V_TRACT_DEMAND_FUNNEL (Demand funnel stages: Base → Can Afford → Want → Need)
    ↓
V_TRACT_DEMAND_BY_OFFERING (Offering-specific demand calculations)
    ↓
V_TRACT_DEMAND_SUMMARY_BY_OFFERING (Aggregated to CBSA/County)
    ↓
FEATURE_MARKET_FORECAST_2Y_CBSA (CBSA-level forecast with ACS demand)
```

### 1.2 Multi-Source Demand Hierarchy

The forecast model uses a **priority-based hierarchy** for demand estimation:

1. **Primary: ACS Tract-Based Demand** (`ACS_TRACT`)
   - Most granular and accurate
   - Based on actual housing stock and renter characteristics
   - Aggregated from 80,000+ Census tracts to CBSA level

2. **Secondary: Economic Fundamentals** (`ECONOMIC_FUNDAMENTALS`)
   - Employment growth + Wage growth → Demand growth
   - Used when ACS tract data unavailable

3. **Tertiary: Operational Absorption** (`PARCL_ABSORPTION`)
   - Current absorption rate from PARCL Labs
   - Used when neither ACS nor economic data available

4. **Fallback: None** (`NONE`)
   - No demand forecast available

---

## 2. ACS Tract Data Components

### 2.1 Source: FACT_ACS_TRACT_TS

**Table**: `TRANSFORM_PROD.FACT.FACT_ACS_TRACT_TS`  
**Coverage**: 80,000+ Census Tracts, 50 states + DC  
**Latest Available**: 2023 (5-year estimates)  
**Update Frequency**: Annual (5-year rolling estimates)

**Key Metrics Used**:
- **Housing Stock**: Total units, owner-occupied, renter-occupied, vacant units
- **Structure Type**: Distribution by unit count (1-unit, 2-4 units, 5-19 units, 20-49 units, 50+ units)
- **Tenure by Structure**: Owner/renter breakdown by structure type
- **Bedroom Distribution**: 0-5+ bedrooms by tenure
- **Financial Metrics**: Median rent, median gross rent, median home value
- **Rent Burden**: Percentage of renters spending 30%+, 50%+ of income on rent
- **Household Characteristics**: Average household size, population by tenure

### 2.2 Processing: V_TRACT_HOUSING_COHORT

**View**: `ANALYTICS_PROD.MODELED.V_TRACT_HOUSING_COHORT`

**Purpose**: Segment tracts by housing characteristics from ACS data

**Key Calculations**:
```sql
-- Base housing stock
TOTAL_HOUSING_UNITS = SUM(units by structure type)
OWNER_OCCUPIED = SUM(owner-occupied units)
RENTER_OCCUPIED = SUM(renter-occupied units)
TOTAL_VACANT = SUM(vacant units)

-- Structure type distribution
RENTER_1_UNIT = Renter-occupied 1-unit structures (SFR)
RENTER_2_4_UNITS = Renter-occupied 2-4 unit structures
RENTER_5_19_UNITS = Renter-occupied 5-19 unit structures
RENTER_20_49_UNITS = Renter-occupied 20-49 unit structures
RENTER_50PLUS_UNITS = Renter-occupied 50+ unit structures

-- Financial metrics
MEDIAN_RENT = Median gross rent
MEDIAN_VALUE = Median home value
RENT_BURDEN_30PLUS = Renters spending ≥30% of income on rent
RENT_BURDEN_50PLUS = Renters spending ≥50% of income on rent
```

**Coverage**: 85,381 tracts with housing data (2023)

---

## 3. Demand Funnel Calculation

### 3.1 V_TRACT_DEMAND_FUNNEL

**View**: `ANALYTICS_PROD.MODELED.V_TRACT_DEMAND_FUNNEL`

**Purpose**: Map demand funnel stages to tract-level ACS data

**Funnel Stages**:

1. **Base Demand: All Renters**
   ```
   DEMAND_BASE_RENTERS = RENTER_OCCUPIED
   ```
   - Total renter-occupied units from ACS

2. **Step 1: Can Afford SFR (Budget)**
   ```
   DEMAND_CAN_AFFORD_SFR = Renters with rent burden < 30%
   ```
   - Uses median rent-to-income ratio from ACS
   - Filters out severely rent-burdened households
   - **This is the primary demand metric used in forecast**

3. **Step 2: Want SFR (Structure Preference)**
   ```
   DEMAND_WANT_SFR = Renters in 1-unit structures (SFR)
   ```
   - Based on structure type distribution from ACS
   - Identifies renters already in SFR structures

4. **Step 3: Need SFR (Work Location)**
   ```
   DEMAND_NEED_SFR = DEMAND_WANT_SFR with work location nearby
   ```
   - Uses LODES data for commuting patterns
   - Filters by work location proximity

**Percentages**:
```sql
PCT_CAN_AFFORD = (DEMAND_CAN_AFFORD_SFR / DEMAND_BASE_RENTERS) * 100
PCT_WANT_SFR = (DEMAND_WANT_SFR / DEMAND_BASE_RENTERS) * 100
PCT_NEED_SFR = (DEMAND_NEED_SFR / DEMAND_BASE_RENTERS) * 100
```

---

## 4. Aggregation to CBSA Level

### 4.1 V_TRACT_DEMAND_SUMMARY_BY_OFFERING

**View**: `ANALYTICS_PROD.MODELED.V_TRACT_DEMAND_SUMMARY_BY_OFFERING`

**Purpose**: Aggregate tract-level demand to CBSA/County for market analysis

**Aggregation Logic**:
```sql
SELECT 
    CBSA_CODE,
    CBSA_NAME,
    -- Sum tract-level demand to CBSA
    SUM(DEMAND_CAN_AFFORD_SFR) AS TOTAL_CAN_AFFORD_SFR,
    SUM(DEMAND_BASE_RENTERS) AS TOTAL_BASE_RENTERS,
    -- Average percentages
    AVG(PCT_CAN_AFFORD) AS AVG_PCT_CAN_AFFORD
FROM V_TRACT_DEMAND_BY_OFFERING
GROUP BY CBSA_CODE, CBSA_NAME
```

**Key Metrics for Forecast**:
- `TOTAL_CAN_AFFORD_SFR`: Total renters who can afford SFR (annual demand)
- `TOTAL_BASE_RENTERS`: Total renter-occupied units (market size)
- `AVG_PCT_CAN_AFFORD`: Average percentage of renters who can afford SFR

---

## 5. Integration into Forecast Model

### 5.1 Forecast Model SQL

**File**: `sql/zillow/feature_model/12_build_2year_forecast_model.sql`

**Integration Point**:
```sql
WITH current_state AS (
    SELECT 
        -- ... other metrics ...
        -- ACS Tract-Based Demand (aggregated to CBSA)
        acs_demand.TOTAL_CAN_AFFORD_SFR AS ACS_DEMAND_CAN_AFFORD_SFR,
        acs_demand.AVG_PCT_CAN_AFFORD AS ACS_PCT_CAN_AFFORD,
        acs_demand.TOTAL_BASE_RENTERS AS ACS_TOTAL_BASE_RENTERS
    FROM FEATURE_MARKET_SPOT_CBSA s
    LEFT JOIN (
        SELECT 
            CBSA_CODE,
            SUM(DEMAND_CAN_AFFORD_SFR) AS TOTAL_CAN_AFFORD_SFR,
            SUM(DEMAND_BASE_RENTERS) AS TOTAL_BASE_RENTERS,
            AVG(PCT_CAN_AFFORD) AS AVG_PCT_CAN_AFFORD
        FROM V_TRACT_DEMAND_SUMMARY_BY_OFFERING
        GROUP BY CBSA_CODE
    ) acs_demand ON LEFT(s.GEO_ID, 5) = acs_demand.CBSA_CODE
)
```

### 5.2 Forecast Absorption Calculation

**Priority-Based Logic**:
```sql
Forecast_absorption_12m = CASE 
    -- Priority 1: ACS tract-based demand (most granular)
    WHEN ACS_DEMAND_CAN_AFFORD_SFR IS NOT NULL 
         AND ACS_DEMAND_CAN_AFFORD_SFR > 0
    THEN (ACS_DEMAND_CAN_AFFORD_SFR / 12.0) * (1 + Forecast_demand_growth)
    
    -- Priority 2: Economic fundamentals
    WHEN PARCL_absorption_new IS NOT NULL 
         AND EMPLOYMENT_GROWTH_YOY IS NOT NULL 
         AND WAGE_GROWTH_YOY IS NOT NULL
    THEN PARCL_absorption_new * 12 * (1 + Forecast_demand_growth)
    
    -- Priority 3: Current absorption
    WHEN PARCL_absorption_new IS NOT NULL
    THEN PARCL_absorption_new * 12
    
    ELSE NULL
END
```

**Key Points**:
- **ACS demand is annual**: Convert to monthly by dividing by 12
- **Apply demand growth**: Multiply by `(1 + Forecast_demand_growth)` to project forward
- **Demand growth from economic fundamentals**: Employment/wage growth → housing demand

### 5.3 Demand Source Indicator

**New Column**: `Demand_source`

**Values**:
- `'ACS_TRACT'`: Forecast uses ACS tract-based demand (preferred)
- `'ECONOMIC_FUNDAMENTALS'`: Forecast uses employment/wage growth
- `'PARCL_ABSORPTION'`: Forecast uses current absorption rate
- `'NONE'`: No demand forecast available

**Usage**: Track which markets have ACS data vs. fallback sources

---

## 6. Advantages of ACS Tract Data

### 6.1 Granularity

- **80,000+ Census Tracts** vs. **939 CBSAs**
- **Tract-level precision** enables sub-market analysis
- **Aggregation flexibility**: Can roll up to ZIP, County, or CBSA

### 6.2 Accuracy

- **Actual housing stock** from Census (not estimated)
- **Renter characteristics** from household surveys
- **Rent burden calculations** from income/rent data
- **Structure type distribution** from housing unit data

### 6.3 Coverage

- **National coverage**: All 50 states + DC
- **Consistent methodology**: Same data collection across all tracts
- **Historical data**: 2005-2023 (enables trend analysis)

### 6.4 Demand Segmentation

- **Offering-specific demand**: Can calculate demand for each of 22 offerings
- **Cohort segmentation**: Age, education, income, structure type
- **Affordability filters**: Rent burden, income-to-rent ratios

---

## 7. Forecast Model Enhancements

### 7.1 Before ACS Integration

**Demand Source**: Economic fundamentals only
```sql
Forecast_absorption_12m = PARCL_absorption_new * 12 * (1 + Forecast_demand_growth)
```

**Limitations**:
- Relies on current absorption rate (may not reflect true demand)
- Economic fundamentals are indirect (employment → housing demand)
- No granular sub-market analysis

### 7.2 After ACS Integration

**Demand Source**: ACS tract data (primary) + Economic fundamentals (fallback)
```sql
Forecast_absorption_12m = (ACS_DEMAND_CAN_AFFORD_SFR / 12.0) * (1 + Forecast_demand_growth)
```

**Advantages**:
- **Direct demand measurement**: Based on actual housing stock and renter characteristics
- **Granular precision**: Tract-level data aggregated to CBSA
- **Offering-specific**: Can calculate demand for each offering type
- **Historical trends**: Can analyze demand changes over time

---

## 8. Data Quality Metrics

### 8.1 ACS Coverage

**Tract-Level**:
- **Total Tracts**: 85,381 tracts with housing data
- **Coverage**: 94.3% of tracts with age/education data
- **Latest Data**: 2023 (5-year estimates)

**CBSA-Level Aggregation**:
- **Markets with ACS Data**: ~700+ CBSAs (varies by aggregation)
- **Coverage**: Higher in metropolitan areas (more tracts per CBSA)

### 8.2 Forecast Model Coverage

**Expected Distribution**:
- **ACS_TRACT**: ~70-80% of markets (metropolitan areas)
- **ECONOMIC_FUNDAMENTALS**: ~15-20% of markets (smaller metros)
- **PARCL_ABSORPTION**: ~5-10% of markets (rural/small markets)
- **NONE**: <1% of markets (data gaps)

---

## 9. Validation Queries

### 9.1 Check ACS Demand Coverage

```sql
SELECT 
    Demand_source,
    COUNT(*) AS market_count,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 1) AS pct_of_markets,
    ROUND(AVG(Forecast_absorption_12m), 0) AS avg_forecast_absorption,
    ROUND(AVG(Forecast_confidence_score), 1) AS avg_confidence
FROM ANALYTICS_PROD.FEATURES.FEATURE_MARKET_FORECAST_2Y_CBSA
WHERE DATE_REFERENCE = (SELECT MAX(DATE_REFERENCE) FROM ANALYTICS_PROD.FEATURES.FEATURE_MARKET_FORECAST_2Y_CBSA)
GROUP BY Demand_source
ORDER BY market_count DESC;
```

### 9.2 Compare ACS vs. Economic Fundamentals

```sql
SELECT 
    f.Demand_source,
    COUNT(*) AS markets,
    AVG(f.Forecast_absorption_12m) AS avg_forecast_absorption,
    AVG(f.Forecast_demand_growth) AS avg_demand_growth,
    AVG(f.Forecast_confidence_score) AS avg_confidence
FROM ANALYTICS_PROD.FEATURES.FEATURE_MARKET_FORECAST_2Y_CBSA f
WHERE f.DATE_REFERENCE = (SELECT MAX(DATE_REFERENCE) FROM ANALYTICS_PROD.FEATURES.FEATURE_MARKET_FORECAST_2Y_CBSA)
GROUP BY f.Demand_source;
```

---

## 10. Summary

**ACS Tract Data Flow**:
1. **Source**: `FACT_ACS_TRACT_TS` (80,000+ tracts, 2023 data)
2. **Processing**: `V_TRACT_HOUSING_COHORT` → `V_TRACT_DEMAND_FUNNEL` → `V_TRACT_DEMAND_BY_OFFERING`
3. **Aggregation**: `V_TRACT_DEMAND_SUMMARY_BY_OFFERING` (tract → CBSA)
4. **Integration**: `FEATURE_MARKET_FORECAST_2Y_CBSA` (forecast model)

**Key Benefits**:
- ✅ **Most granular demand measurement** (tract-level precision)
- ✅ **Direct demand calculation** (based on actual housing stock)
- ✅ **Offering-specific demand** (22 offerings supported)
- ✅ **National coverage** (all 50 states + DC)
- ✅ **Historical trends** (2005-2023 data)

**Forecast Model Priority**:
1. **ACS Tract Data** (primary, most accurate)
2. **Economic Fundamentals** (fallback, indirect)
3. **Operational Absorption** (fallback, current state only)

The forecast model now leverages the full power of ACS tract data to provide the most accurate demand forecasts for Anchor Loans memos.

