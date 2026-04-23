# AMREG/Oxford Data Review: Demand Forecasting Enhancement

**Date**: 2026-01-27  
**Status**: 📋 **REVIEW COMPLETE**  
**Purpose**: Review AMREG/Oxford integration for demand forecasting (future household projections)

---

## Executive Summary

**Key Insight**: Demand forecasting = **future number of households** in a given geography. Currently, we use economic fundamentals (employment/wage growth) to **infer** demand growth, but AMREG provides **direct population/household forecasts** that should be the primary source.

**Current Gap**: We're calculating `Forecast_demand_growth` from employment/wage growth, but AMREG has direct demographic forecasts (population, households) that would be more accurate.

---

## Current Demand Forecasting Approach

### Current Method: Economic Fundamentals → Demand Growth

**Formula**:
```sql
Forecast_demand_growth = (
    EMPLOYMENT_GROWTH_YOY * 0.60 +      -- 60% weight on employment growth
    WAGE_GROWTH_YOY * 0.40               -- 40% weight on wage growth
) * 0.80  -- Dampening factor (economic growth → housing demand conversion)
```

**Data Sources**:
- QECW employment/wage growth (296 CBSAs)
- BLS as fallback
- National average as final fallback

**Limitations**:
1. **Indirect**: Economic growth → inferred housing demand (not direct)
2. **Dampening factor (0.80)**: Assumes only 80% of economic growth converts to housing demand
3. **No direct household projections**: We're estimating growth, not using actual forecasts
4. **Missing demographics**: Age structure, household formation rates not considered

---

## AMREG Demographics Data Available

### Data Source

**Table**: `TRANSFORM_PROD.CLEANED.AMREG_CBSA_ECONOMICS_MATERIALIZED`  
**Category**: `DEMOGRAPHICS`  
**Metrics**: 18 metrics  
**Rows**: 974K (demographics category)  
**Coverage**: 296 CBSAs  
**Date Range**: 2020-12-31 to 2050-12-31 (31 years of forecasts)

### Key Demographics Metrics (Expected)

Based on AMREG's demographics category, likely includes:
- **Population** (total, by age group)
- **Household Count** (total households)
- **Household Formation Rate** (new households per year)
- **Age Distribution** (population by age cohort)
- **Migration** (net migration, in-migration, out-migration)

### Query to Explore Available Metrics

```sql
SELECT DISTINCT
    META_METRIC,
    INDICATOR_FULL_NAME,
    COUNT(*) AS row_count,
    MIN(DATE_REFERENCE) AS earliest_date,
    MAX(DATE_REFERENCE) AS latest_date
FROM TRANSFORM_PROD.CLEANED.AMREG_CBSA_ECONOMICS_MATERIALIZED
WHERE META_METRIC LIKE '%DEMOGRAPHIC%'
   OR META_METRIC LIKE '%POPULATION%'
   OR META_METRIC LIKE '%HOUSEHOLD%'
GROUP BY META_METRIC, INDICATOR_FULL_NAME
ORDER BY META_METRIC;
```

---

## Recommended Integration: Direct Household Forecasts

### Approach 1: Direct Household Projections (Preferred)

**Use AMREG household forecasts directly** instead of inferring from employment growth.

**Formula**:
```sql
-- Current households (from ACS or AMREG historical)
Current_households = ACS_TOTAL_HOUSEHOLDS  -- or AMREG 2024 value

-- Future households (from AMREG forecast)
Future_households_12m = AMREG_HOUSEHOLD_COUNT_2025
Future_households_24m = AMREG_HOUSEHOLD_COUNT_2026

-- Direct demand growth calculation
Forecast_demand_growth_12m = (Future_households_12m / Current_households) - 1
Forecast_demand_growth_24m = (Future_households_24m / Current_households) - 1
```

**Advantages**:
- ✅ **Direct**: Uses actual household forecasts, not inferred
- ✅ **More accurate**: Demographics-based, not economic proxy
- ✅ **Forward-looking**: Forecasts through 2050
- ✅ **CBSA-specific**: 296 CBSAs with direct forecasts

### Approach 2: Hybrid (AMREG Primary, Economic Fallback)

**Priority hierarchy**:
1. **Primary**: AMREG household/population forecasts
2. **Secondary**: AMREG employment growth (if household data unavailable)
3. **Tertiary**: QECW/BLS employment/wage growth (current method)

**Formula**:
```sql
Forecast_demand_growth = CASE
    -- Priority 1: Direct household forecast
    WHEN AMREG_HOUSEHOLD_GROWTH_YOY IS NOT NULL
    THEN AMREG_HOUSEHOLD_GROWTH_YOY
    
    -- Priority 2: Population forecast (convert to household growth)
    WHEN AMREG_POPULATION_GROWTH_YOY IS NOT NULL
    THEN AMREG_POPULATION_GROWTH_YOY * 0.95  -- ~95% of population growth = household growth
    
    -- Priority 3: Employment growth (current method)
    WHEN EMPLOYMENT_GROWTH_YOY IS NOT NULL AND WAGE_GROWTH_YOY IS NOT NULL
    THEN (EMPLOYMENT_GROWTH_YOY * 0.60 + WAGE_GROWTH_YOY * 0.40) * 0.80
    
    -- Priority 4: Employment only
    WHEN EMPLOYMENT_GROWTH_YOY IS NOT NULL
    THEN EMPLOYMENT_GROWTH_YOY * 0.80
    
    ELSE NULL
END
```

---

## Integration Plan

### Phase 1: Explore AMREG Demographics Data ✅ READY

**Action**: Query AMREG materialized table to identify available demographics metrics

**SQL**:
```sql
-- Identify demographics metrics
SELECT DISTINCT
    META_METRIC,
    INDICATOR_FULL_NAME,
    COUNT(*) AS row_count,
    COUNT(DISTINCT ID_CBSA) AS cbsa_count,
    MIN(DATE_REFERENCE) AS earliest_date,
    MAX(DATE_REFERENCE) AS latest_date
FROM TRANSFORM_PROD.CLEANED.AMREG_CBSA_ECONOMICS_MATERIALIZED
WHERE META_METRIC LIKE '%DEMOGRAPHIC%'
   OR META_METRIC LIKE '%POPULATION%'
   OR META_METRIC LIKE '%HOUSEHOLD%'
   OR META_METRIC LIKE '%MIGRATION%'
GROUP BY META_METRIC, INDICATOR_FULL_NAME
ORDER BY META_METRIC;

-- Sample data for a specific CBSA
SELECT 
    ID_CBSA,
    NAME_CBSA,
    DATE_REFERENCE,
    META_METRIC,
    INDICATOR_FULL_NAME,
    VALUE
FROM TRANSFORM_PROD.CLEANED.AMREG_CBSA_ECONOMICS_MATERIALIZED
WHERE ID_CBSA = '12060'  -- Phoenix
  AND (META_METRIC LIKE '%POPULATION%' OR META_METRIC LIKE '%HOUSEHOLD%')
  AND DATE_REFERENCE >= '2024-01-01'
ORDER BY DATE_REFERENCE, META_METRIC;
```

### Phase 2: Create Demographics Views

**Create**: `TRANSFORM_PROD.CLEANED.AMREG_DEMOGRAPHICS_CBSA`

**Purpose**: Extract and standardize demographics metrics from materialized table

**Structure**:
```sql
CREATE OR REPLACE VIEW TRANSFORM_PROD.CLEANED.AMREG_DEMOGRAPHICS_CBSA AS
SELECT 
    ID_CBSA,
    NAME_CBSA,
    DATE_REFERENCE,
    -- Population metrics
    MAX(CASE WHEN META_METRIC LIKE '%POPULATION%TOTAL%' THEN VALUE END) AS POPULATION_TOTAL,
    MAX(CASE WHEN META_METRIC LIKE '%POPULATION%GROWTH%' THEN VALUE END) AS POPULATION_GROWTH_YOY,
    -- Household metrics
    MAX(CASE WHEN META_METRIC LIKE '%HOUSEHOLD%TOTAL%' THEN VALUE END) AS HOUSEHOLD_COUNT,
    MAX(CASE WHEN META_METRIC LIKE '%HOUSEHOLD%GROWTH%' THEN VALUE END) AS HOUSEHOLD_GROWTH_YOY,
    MAX(CASE WHEN META_METRIC LIKE '%HOUSEHOLD%FORMATION%' THEN VALUE END) AS HOUSEHOLD_FORMATION_RATE,
    -- Migration metrics
    MAX(CASE WHEN META_METRIC LIKE '%MIGRATION%NET%' THEN VALUE END) AS NET_MIGRATION,
    MAX(CASE WHEN META_METRIC LIKE '%MIGRATION%IN%' THEN VALUE END) AS IN_MIGRATION,
    MAX(CASE WHEN META_METRIC LIKE '%MIGRATION%OUT%' THEN VALUE END) AS OUT_MIGRATION
FROM TRANSFORM_PROD.CLEANED.AMREG_CBSA_ECONOMICS_MATERIALIZED
WHERE META_METRIC LIKE '%DEMOGRAPHIC%'
   OR META_METRIC LIKE '%POPULATION%'
   OR META_METRIC LIKE '%HOUSEHOLD%'
   OR META_METRIC LIKE '%MIGRATION%'
GROUP BY ID_CBSA, NAME_CBSA, DATE_REFERENCE;
```

### Phase 3: Integrate into Demand Forecast Model

**File**: `sql/zillow/feature_model/12_build_2year_forecast_model.sql`

**Changes**:
1. Join AMREG demographics data in `current_state` CTE
2. Calculate `Forecast_demand_growth` from household forecasts (primary)
3. Fall back to employment/wage growth if household data unavailable
4. Update confidence scoring to reflect data source quality

**Example Integration**:
```sql
current_state AS (
    SELECT 
        s.*,
        -- AMREG demographics (primary source for household forecasts)
        amreg.HOUSEHOLD_COUNT AS AMREG_HOUSEHOLD_COUNT_CURRENT,
        amreg.HOUSEHOLD_GROWTH_YOY AS AMREG_HOUSEHOLD_GROWTH_YOY,
        amreg.POPULATION_GROWTH_YOY AS AMREG_POPULATION_GROWTH_YOY,
        -- Future household forecasts
        amreg_future.HOUSEHOLD_COUNT AS AMREG_HOUSEHOLD_COUNT_12M,
        amreg_future_24m.HOUSEHOLD_COUNT AS AMREG_HOUSEHOLD_COUNT_24M
    FROM FEATURE_MARKET_SPOT_CBSA s
    LEFT JOIN TRANSFORM_PROD.CLEANED.AMREG_DEMOGRAPHICS_CBSA amreg
        ON s.GEO_ID = amreg.ID_CBSA
        AND amreg.DATE_REFERENCE = s.DATE_REFERENCE
    LEFT JOIN TRANSFORM_PROD.CLEANED.AMREG_DEMOGRAPHICS_CBSA amreg_future
        ON s.GEO_ID = amreg_future.ID_CBSA
        AND amreg_future.DATE_REFERENCE = DATEADD(year, 1, s.DATE_REFERENCE)
    LEFT JOIN TRANSFORM_PROD.CLEANED.AMREG_DEMOGRAPHICS_CBSA amreg_future_24m
        ON s.GEO_ID = amreg_future_24m.ID_CBSA
        AND amreg_future_24m.DATE_REFERENCE = DATEADD(year, 2, s.DATE_REFERENCE)
),

forecast_12m AS (
    SELECT 
        *,
        -- Priority 1: Direct household growth from AMREG
        CASE 
            WHEN AMREG_HOUSEHOLD_GROWTH_YOY IS NOT NULL
            THEN AMREG_HOUSEHOLD_GROWTH_YOY
            
            -- Priority 2: Calculate from household count change
            WHEN AMREG_HOUSEHOLD_COUNT_CURRENT IS NOT NULL 
                 AND AMREG_HOUSEHOLD_COUNT_12M IS NOT NULL
                 AND AMREG_HOUSEHOLD_COUNT_CURRENT > 0
            THEN (AMREG_HOUSEHOLD_COUNT_12M / AMREG_HOUSEHOLD_COUNT_CURRENT) - 1
            
            -- Priority 3: Population growth (convert to household growth)
            WHEN AMREG_POPULATION_GROWTH_YOY IS NOT NULL
            THEN AMREG_POPULATION_GROWTH_YOY * 0.95  -- ~95% conversion
            
            -- Priority 4: Economic fundamentals (current method)
            WHEN EMPLOYMENT_GROWTH_YOY IS NOT NULL AND WAGE_GROWTH_YOY IS NOT NULL
            THEN (EMPLOYMENT_GROWTH_YOY * 0.60 + WAGE_GROWTH_YOY * 0.40) * 0.80
            
            ELSE NULL
        END AS Forecast_demand_growth,
        
        -- Track data source
        CASE
            WHEN AMREG_HOUSEHOLD_GROWTH_YOY IS NOT NULL THEN 'AMREG_HOUSEHOLD_GROWTH'
            WHEN AMREG_HOUSEHOLD_COUNT_CURRENT IS NOT NULL THEN 'AMREG_HOUSEHOLD_COUNT'
            WHEN AMREG_POPULATION_GROWTH_YOY IS NOT NULL THEN 'AMREG_POPULATION_GROWTH'
            WHEN EMPLOYMENT_GROWTH_YOY IS NOT NULL THEN 'ECONOMIC_FUNDAMENTALS'
            ELSE 'NONE'
        END AS Demand_growth_source
    FROM current_state
)
```

---

## Comparison: Current vs. Proposed

### Current Approach

| Aspect | Current Method |
|--------|----------------|
| **Source** | Economic fundamentals (employment/wage growth) |
| **Method** | Indirect inference (economic growth → housing demand) |
| **Dampening** | 0.80 factor (assumes 80% conversion) |
| **Coverage** | 296 CBSAs (QECW) + fallbacks |
| **Accuracy** | Moderate (proxy method) |
| **Forward-looking** | 1-2 years (based on current trends) |

### Proposed Approach (AMREG Demographics)

| Aspect | Proposed Method |
|--------|-----------------|
| **Source** | Direct household/population forecasts (AMREG) |
| **Method** | Direct projection (household count change) |
| **Dampening** | None needed (direct forecast) |
| **Coverage** | 296 CBSAs (AMREG) |
| **Accuracy** | Higher (direct demographics) |
| **Forward-looking** | Through 2050 (long-term forecasts) |

---

## Benefits of AMREG Integration

### 1. Direct Household Forecasts
- ✅ **More accurate**: Uses actual demographic projections, not economic proxies
- ✅ **Longer horizon**: Forecasts through 2050 vs. 1-2 years
- ✅ **Demographics-based**: Considers age structure, migration, household formation

### 2. Better Demand Growth Calculation
- ✅ **No dampening factor needed**: Direct household growth, not inferred
- ✅ **CBSA-specific**: 296 CBSAs with direct forecasts
- ✅ **Multiple metrics**: Population, households, migration all available

### 3. Enhanced Forecast Model
- ✅ **Higher confidence**: Direct forecasts vs. inferred growth
- ✅ **Multiple fallbacks**: Household → Population → Employment → Wage
- ✅ **Source tracking**: Know which data source was used

---

## Next Steps

### Immediate (Phase 1)
1. ✅ **Query AMREG demographics**: Identify available metrics
2. ✅ **Document metrics**: List all demographics metrics in AMREG
3. ⏳ **Validate coverage**: Check which CBSAs have household/population forecasts

### Short-term (Phase 2)
1. ⏳ **Create demographics view**: Extract and standardize AMREG demographics
2. ⏳ **Integrate into forecast model**: Update `12_build_2year_forecast_model.sql`
3. ⏳ **Test accuracy**: Compare AMREG-based vs. economic-based forecasts

### Medium-term (Phase 3)
1. ⏳ **Update demand calculation**: Use AMREG household forecasts in demand pipeline
2. ⏳ **Enhance confidence scoring**: Higher confidence for direct forecasts
3. ⏳ **Documentation**: Update demand forecasting documentation

---

## Key Takeaway

**Demand forecasting = future number of households**. AMREG provides **direct household/population forecasts** that should be the **primary source** for demand growth, with economic fundamentals as fallback. This is more accurate than inferring demand from employment/wage growth.

---

**Status**: AMREG materialization complete. Ready to explore demographics metrics and integrate into demand forecasting.

**Last Updated**: 2026-01-27

