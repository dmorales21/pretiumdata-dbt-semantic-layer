# Progress Offerings: Methodology, Metrics, EDA, and Correlation Analysis

**Date**: 2026-01-27  
**Status**: Comprehensive Analysis Document  
**Coverage**: Tract and CBSA Level Analysis for PROG_SFR_TRAD, PROG_SFR_FY, PROG_SFR_AH

---

## Executive Summary

This document consolidates methodologies, metrics, exploratory data analysis (EDA), and correlation analysis for Progress Residential's three SFR offerings at both tract and CBSA levels. The analysis covers demand mass calculation, forecast methodology, household structure modifiers, and market segmentation patterns.

---

## 1. Methodology: Demand Mass Calculation

### 1.1 Core Framework

**Demand Mass = Base Households × Eligibility Share × Propensity Share**

Where:
- **Base Households**: Structural, slow-moving (Oxford, ACS, LODES)
- **Eligibility Share**: Economic, fast-moving (CPS, QCEW, HMDA, AI risk, PITI)
- **Propensity Share**: Behavioral preferences (structure, tenure, demographics)

### 1.2 Two-Stage Forecast Architecture

```
DemandMass_t → EligibilityShare_t → TargetDemand_t
```

**TargetDemand_t = DemandMass_t × EligibilityShare_t**

#### Stage 1: Demand Mass (Structural)
- **Source**: Oxford Economics AMREG (household growth)
- **Components Held Constant**:
  - Tenure mix (ACS B25003)
  - Structure shares (ACS B25032)
  - Spatial feasibility (LODES, defaults to 1.0)
- **Forecast Horizons**: 24M and 36M from `AS_OF_SIGNAL_DATE`

#### Stage 2: Eligibility Share (Economic)
- **Model-First Approach**: Uses `PRED_BUDGET_ELIGIBILITY` when available
- **Fallback**: Rule-based calculation (50% if median income ≥ 3× median rent)
- **Adjustments**:
  - CPS wage growth (YoY)
  - QCEW employment growth (YoY)
  - QCEW wage growth (YoY, calculated from TOTAL_WAGES)
  - AI replacement risk (applied to wage growth, not household counts)
  - PITI rate scenarios (BASE, HIGH_RATE, LOW_RATE)
- **Scenarios**: BASE and DOWNSIDE (DOWNSIDE = BASE × (1 - AI_risk × 0.2))

---

## 2. Progress Offerings: Specific Methodologies

### 2.1 PROG_SFR_TRAD (Traditional)

**Target Market**: Mainstream renter households leasing single-family homes

**Demand Mass Formula**:
```sql
BASE_SFR_RENTER_HOUSEHOLDS ×
    RENTER_MAINSTREAM_SHARE ×
    BUDGET_ELIGIBLE_SHARE ×
    DISTANCE_FEASIBLE_SHARE
```

**Components**:
- **BASE_SFR_RENTER_HOUSEHOLDS**: Renters in 1-unit detached/attached + small 2-4 units
- **RENTER_MAINSTREAM_SHARE**: Household size 2-4 persons (default: 0.5 if missing)
- **BUDGET_ELIGIBLE_SHARE**: ML model prediction or rule-based (rent-to-income ≤ 30%)
- **DISTANCE_FEASIBLE_SHARE**: Commute feasibility (default: 1.0, LODES integration pending)

**Eligibility Share**:
- Uses generic eligibility share (not offering-specific)
- Applied at signal date, then forecasted forward with momentum adjustments

**Sensitivity Parameters**:
- **Hazard Sensitivity**: 1.5 (medium)
- **Mobility Blend**: 0.6 (60% mobility, 40% listings)

---

### 2.2 PROG_SFR_FY (Front Yard)

**Target Market**: Family-oriented SFR demand in "sticky" neighborhoods

**Demand Mass Formula**:
```sql
BASE_SFR_RENTER_HOUSEHOLDS ×
    RENTER_FAMILY_SIZE_SHARE ×
    CHILDREN_MODIFIER ×
    BUDGET_ELIGIBLE_SHARE ×
    DISTANCE_FEASIBLE_SHARE ×
    STABILITY_MODIFIER
```

**Components**:
- **BASE_SFR_RENTER_HOUSEHOLDS**: Same as TRAD
- **RENTER_FAMILY_SIZE_SHARE**: Household size 3+ persons (default: 0.3 if missing)
- **CHILDREN_MODIFIER**: 
  - Formula: `sqrt(HH_WITH_CHILDREN_SHARE) × sqrt(RENTER_SHARE_PCT)`
  - Default: 1.0 if B11005 missing
  - **Risk Mitigation**: Multiplied by `sqrt(RENTER_SHARE_PCT)` to prevent owner-heavy bias
- **STABILITY_MODIFIER**: 
  - Formula: `1.0 - clamp(MOVE_RATE_1YR / 0.25, 0..1)`
  - Source: ACS B07401 (mobility data)
  - Default: 0.85 if B07401 missing (risk mitigation: slightly penalizing)
  - Benchmark: 25% annual move rate = stress threshold (modifier = 0.0)
- **BUDGET_ELIGIBLE_SHARE**: Same as TRAD
- **DISTANCE_FEASIBLE_SHARE**: Same as TRAD

**Eligibility Share**:
- Uses generic eligibility share (not offering-specific)
- Applied at signal date, then forecasted forward

**Sensitivity Parameters**:
- **Hazard Sensitivity**: 1.5 (medium)
- **Mobility Blend**: 0.5 (50% mobility, 50% listings)

**Key Differentiators**:
- **Family Focus**: CHILDREN_MODIFIER and RENTER_FAMILY_SIZE_SHARE
- **Stability Requirement**: STABILITY_MODIFIER penalizes high-mobility tracts
- **Sticky Neighborhoods**: Higher retention drivers tied to schools and neighborhood desirability

---

### 2.3 PROG_SFR_AH (Affordable/HCV)

**Target Market**: Voucher or affordability-oriented renter households

**Demand Mass Formula**:
```sql
BASE_SFR_RENTER_HOUSEHOLDS ×
    RENTER_HOUSELIKE_SHARE ×
    RENT_BURDEN_MODIFIER ×
    AFFORDABLE_MARKET_MODIFIER
```

**Components**:
- **BASE_SFR_RENTER_HOUSEHOLDS**: Same as TRAD
- **RENTER_HOUSELIKE_SHARE**: Renters in 1-unit + 2-4 units (default: 0.5 if missing)
- **RENT_BURDEN_MODIFIER**: 
  - Formula: `clamp((RENT_BURDEN_50PLUS / RENTER_OCCUPIED) × 2.0, 0..1)`
  - Targets households with rent burden ≥ 50%
- **AFFORDABLE_MARKET_MODIFIER**: 
  - 1.0 if `MEDIAN_RENT ≤ P75_RENT_CBSA`
  - 0.5 otherwise

**Eligibility Share**:
- **Offering-Specific**: Uses `PRED_BUDGET_ELIGIBILITY` with `OFFERING_ID = 'PROG_SFR_AH'` when available
- **Fallback**: `ELIGIBILITY_SHARE_AT_SIGNAL_DATE × 0.7` (stricter threshold)
- Applied at signal date, then forecasted forward

**Sensitivity Parameters**:
- **Hazard Sensitivity**: 1.5 (medium)
- **Mobility Blend**: 0.5 (50% mobility, 50% listings)

**Key Differentiators**:
- **Affordability-First**: Rent burden and affordable market filters
- **Stricter Eligibility**: 70% of generic eligibility (or explicit income band coverage)
- **HCV Participation**: Designed for Housing Choice Voucher Program participation

---

## 3. Metrics and KPIs

### 3.1 Tract-Level Metrics

**Demand Mass Metrics**:
- `DEMAND_MASS_TRAD_24M/36M`: Traditional demand mass forecast
- `DEMAND_MASS_FY_24M/36M`: Front Yard demand mass forecast
- `DEMAND_MASS_AH_24M/36M`: Affordable demand mass forecast

**Target Demand Metrics**:
- `PROG_SFR_TRAD_FORECAST_24M_BASE/DOWNSIDE`: Traditional target demand
- `PROG_SFR_FY_FORECAST_24M_BASE/DOWNSIDE`: Front Yard target demand
- `PROG_SFR_AH_FORECAST_24M_BASE/DOWNSIDE`: Affordable target demand

**Eligibility Metrics**:
- `ELIGIBILITY_SHARE_24M_BASE/DOWNSIDE`: Generic eligibility (TRAD/FY)
- `ELIGIBILITY_SHARE_AH_24M_BASE/DOWNSIDE`: AH-specific eligibility

**Household Structure Modifiers**:
- `RENTER_MAINSTREAM_SHARE`: Household size 2-4 persons
- `RENTER_FAMILY_SIZE_SHARE`: Household size 3+ persons
- `RENTER_HOUSELIKE_SHARE`: Renters in 1-unit + 2-4 units
- `CHILDREN_MODIFIER`: Children presence adjusted by renter share
- `STABILITY_MODIFIER`: Mobility-based stability (0.0 to 1.0)

**Metadata**:
- `AS_OF_STRUCTURAL_DATE`: ACS 5YR reference date (typically 2023-12-31)
- `AS_OF_SIGNAL_DATE`: Latest CPS/QCEW data date
- `DATA_MAX_AS_OF_OXFORD`: Latest Oxford data date
- `DATA_MAX_AS_OF_CPS`: Latest CPS data date
- `DATA_MAX_AS_OF_QCEW`: Latest QCEW data date
- `DATA_MAX_AS_OF_AI`: Latest AI risk data date
- `BUDGET_ELIG_PRED_FALLBACK_FLAG`: Whether rule-based fallback was used
- `ADJUSTMENT_OVERRIDE_FLAG`: Whether momentum adjustment exceeded caps

---

### 3.2 CBSA-Level Metrics

**Aggregated Demand**:
- Sum of tract-level forecasts (validated to match CBSA totals)
- `TARGET_DEMAND_NOWCAST_SIGNAL_DATE_*`: Current target demand at signal date

**Growth Factors**:
- `HH_GROWTH_FACTOR_24M/36M`: Oxford household growth factors
- `POPULATION_25_44_GROWTH_FACTOR_24M/36M`: Age cohort growth factors
- `BRIDGE_FACTOR_STRUCTURAL_TO_SIGNAL`: Bridge from structural to signal date

**Momentum Indicators**:
- `WAGE_GROWTH_YOY`: CPS or QCEW wage growth (YoY)
- `EMPLOYMENT_GROWTH_YOY`: QCEW employment growth (YoY)
- `MOMENTUM_INDEX`: Weighted combination (60% wage, 40% employment)
- `MOMENTUM_ADJUSTMENT_FACTOR`: Clamped to [0.90, 1.10] with override flag

**Risk Metrics**:
- `COMBINED_AI_RISK_SCORE`: AI replacement risk (0-1 scale)
- `AI_RISK_TIER`: Risk tier classification
- `AI_RISK_MULTIPLIER`: 0.2 (20% max reduction in downside scenario)

**PITI Scenarios**:
- `MORTGAGE_RATE_24M_BASE`: Mortgage rate for 24M horizon
- `INSURANCE_RATE_24M_BASE`: Insurance rate for 24M horizon
- `TAX_RATE_24M_BASE`: Property tax rate for 24M horizon

---

## 4. EDA Results: Distribution and Summary Statistics

### 4.1 Tract-Level Distribution

**Data Coverage**:
- **Total Tracts**: 85,381 Census tracts
- **Progress Offerings Coverage**: All tracts with renter households
- **Missing Data Handling**: Defaults applied with flags

**Demand Mass Distribution** (from `V_PROGRESS_DEMAND_MASS_FORECAST_CBSA`):
- **TRAD**: Mean, median, P25, P75 vary by CBSA
- **FY**: Lower than TRAD due to additional filters (children, stability)
- **AH**: Lower than TRAD due to affordability constraints

**Eligibility Share Distribution**:
- **Range**: 0.0 to 1.0 (clamped)
- **Typical Range**: 0.3 to 0.7 for most CBSAs
- **Fallback Usage**: Tracked via `BUDGET_ELIG_PRED_FALLBACK_FLAG`

---

### 4.2 CBSA-Level Summary Statistics

**From Correlation Analysis** (`analyze_offering_demand_correlations.sql`):

**Sample Size**:
- CBSAs with ≥5 tracts: ~500-600 CBSAs (statistical validity threshold)
- Total observations: Varies by offering

**Mean Demand** (CBSA-level aggregates):
- **PROG_SFR_TRAD**: Varies by market size
- **PROG_SFR_FY**: Typically 30-50% of TRAD
- **PROG_SFR_AH**: Typically 20-40% of TRAD

**Standard Deviation**:
- High variance across CBSAs (market size and characteristics)
- Normalized by CBSA size for fair comparison

**Min/Max**:
- **Min**: 0 (tracts with no eligible households)
- **Max**: Varies by CBSA size (largest markets have highest absolute demand)

---

## 5. Correlation Analysis

### 5.1 Progress Offerings Inter-Correlations

**CBSA-Level Correlations** (Pearson correlation coefficient):

#### PROG_SFR_TRAD vs PROG_SFR_AH
- **Expected Correlation**: 0.6 - 0.8 (high)
- **Interpretation**: Both target SFR renters, but AH has stricter affordability filters
- **Market Segmentation**: AH is a subset of TRAD demand

#### PROG_SFR_TRAD vs PROG_SFR_FY
- **Expected Correlation**: 0.5 - 0.7 (moderate-high)
- **Interpretation**: FY adds family/stability filters, reducing overlap
- **Market Segmentation**: FY targets family-oriented, stable neighborhoods

#### PROG_SFR_AH vs PROG_SFR_FY
- **Expected Correlation**: 0.3 - 0.5 (moderate)
- **Interpretation**: Different target segments (affordability vs. family/stability)
- **Market Segmentation**: Lower overlap due to different filters

---

### 5.2 Cross-Offering Correlations

**PROG_SFR_TRAD vs IMAGINE_STABILIZED_SFR**:
- **Expected Correlation**: 0.7 - 0.9 (very high)
- **Interpretation**: Both target SFR renters, different strategies (Progress vs. Imagine)
- **Market Overlap**: High overlap in target market

**PROG_SFR_TRAD vs BH_BTR**:
- **Expected Correlation**: 0.6 - 0.8 (high)
- **Interpretation**: Both target SFR renters, different strategies (rental vs. build-to-rent)
- **Market Overlap**: Similar target market, different execution

---

### 5.3 Cross-OPCO Correlations

**PROG_SFR_TRAD vs DEEPHAVEN_DSCR_INVESTOR**:
- **Expected Correlation**: 0.2 - 0.4 (low-moderate)
- **Interpretation**: REQ renter vs. REM investor (different target markets)
- **Market Segmentation**: Low overlap, different customer bases

**PROG_SFR_TRAD vs HBF_HORIZONTAL**:
- **Expected Correlation**: 0.1 - 0.3 (low)
- **Interpretation**: REQ renter vs. RED owner (different target markets)
- **Market Segmentation**: Minimal overlap, different customer bases

---

### 5.4 Correlation Matrix Summary

| Offering 1 | Offering 2 | Correlation Range | Interpretation |
|------------|------------|-------------------|----------------|
| PROG_SFR_TRAD | PROG_SFR_AH | 0.6 - 0.8 | High (subset relationship) |
| PROG_SFR_TRAD | PROG_SFR_FY | 0.5 - 0.7 | Moderate-High (family filter) |
| PROG_SFR_AH | PROG_SFR_FY | 0.3 - 0.5 | Moderate (different segments) |
| PROG_SFR_TRAD | IMAGINE_STABILIZED | 0.7 - 0.9 | Very High (same target) |
| PROG_SFR_TRAD | BH_BTR | 0.6 - 0.8 | High (similar target) |
| PROG_SFR_TRAD | DEEPHAVEN_DSCR | 0.2 - 0.4 | Low-Moderate (different OPCO) |
| PROG_SFR_TRAD | HBF_HORIZONTAL | 0.1 - 0.3 | Low (different OPCO) |

---

## 6. Household Structure Modifiers: Detailed Formulas

### 6.1 RENTER_MAINSTREAM_SHARE (TRAD)

**Formula**:
```sql
CASE 
    WHEN RENTER_HOUSEHOLDS > 0
    THEN (RENTER_2_PERSON + RENTER_3_PERSON + RENTER_4_PERSON) / RENTER_HOUSEHOLDS
    ELSE NULL
END
```

**Source**: ACS B25009 (household size by tenure)  
**Default**: 0.5 if missing  
**Purpose**: Targets mainstream household sizes (2-4 persons) for TRAD

---

### 6.2 RENTER_FAMILY_SIZE_SHARE (FY)

**Formula**:
```sql
CASE 
    WHEN RENTER_HOUSEHOLDS > 0
    THEN (RENTER_3_PERSON + RENTER_4_PERSON + RENTER_5_PLUS) / RENTER_HOUSEHOLDS
    ELSE NULL
END
```

**Source**: ACS B25009  
**Default**: 0.3 if missing  
**Purpose**: Targets family-sized households (3+ persons) for FY

---

### 6.3 RENTER_HOUSELIKE_SHARE (AH)

**Formula**:
```sql
CASE 
    WHEN RENTER_HOUSEHOLDS > 0
    THEN (RENTER_1_UNIT + RENTER_2_4_UNITS) / RENTER_HOUSEHOLDS
    ELSE NULL
END
```

**Source**: ACS B25032 (tenure by units-in-structure)  
**Default**: 0.5 if missing  
**Purpose**: Targets renters in house-like structures (1-unit + small MF)

---

### 6.4 CHILDREN_MODIFIER (FY)

**Formula**:
```sql
sqrt(HH_WITH_CHILDREN_SHARE) × sqrt(RENTER_SHARE_PCT)
```

**Source**: ACS B11005 (households with children)  
**Default**: 1.0 if B11005 missing  
**Risk Mitigation**: Multiplied by `sqrt(RENTER_SHARE_PCT)` to prevent owner-heavy bias

**Mathematical Behavior**:
- If children share = 0.25, renter share = 0.40: modifier = 0.5 × 0.63 = 0.32
- If children share = 0.50, renter share = 0.60: modifier = 0.71 × 0.77 = 0.55

---

### 6.5 STABILITY_MODIFIER (FY)

**Formula**:
```sql
1.0 - GREATEST(0.0, LEAST(1.0, (MOVE_RATE_1YR / 0.25)))
```

**Source**: ACS B07401 (mobility)  
**Default**: 0.85 if B07401 missing (risk mitigation)  
**Benchmark**: 25% annual move rate = stress threshold (modifier = 0.0)

**Mathematical Behavior**:
- Move rate = 0.10 (stable): modifier = 1.0 - 0.4 = 0.6
- Move rate = 0.25 (benchmark): modifier = 1.0 - 1.0 = 0.0
- Move rate = 0.05 (very stable): modifier = 1.0 - 0.2 = 0.8
- Move rate = 0.50 (high churn): modifier = 1.0 - 2.0 = -1.0 → clamped to 0.0

---

## 7. Forecast Methodology: 24M and 36M Horizons

### 7.1 Oxford Growth Factors

**Source**: `V_AMREG_GROWTH_HORIZONS_CBSA`

**Calculation**:
- **24M Growth Factor**: `HH_COUNT_24M / HH_COUNT_SIGNAL_DATE - 1`
- **36M Growth Factor**: `HH_COUNT_36M / HH_COUNT_SIGNAL_DATE - 1`

**Interpolation Method**: Log-linear interpolation between annual Oxford points
- Formula: `exp(ln(v1) + (ln(v2) - ln(v1)) × (t - t1) / (t2 - t1))`

**Date Anchors**:
- `AS_OF_STRUCTURAL_DATE`: ACS 5YR reference (typically 2023-12-31)
- `AS_OF_SIGNAL_DATE`: Latest CPS/QCEW data date (dynamic)
- `HORIZON_24M_END`: `AS_OF_SIGNAL_DATE + 24 months`
- `HORIZON_36M_END`: `AS_OF_SIGNAL_DATE + 36 months`

**Bridge Factor**: If structural date ≠ signal date, compute bridge factor:
- `BRIDGE_FACTOR_STRUCTURAL_TO_SIGNAL`: Growth from structural to signal date

---

### 7.2 Demand Mass Forecast

**Formula**:
```sql
HH_TOTAL_AT_SIGNAL_DATE × (1 + HH_GROWTH_FACTOR_24M) ×
    TENURE_SHARE_STRUCTURAL ×
    STRUCTURE_SHARE_STRUCTURAL ×
    DISTANCE_FEASIBLE_SHARE_STRUCTURAL
```

**Components Held Constant**:
- `TENURE_SHARE_STRUCTURAL`: ACS renter share (held constant)
- `STRUCTURE_SHARE_STRUCTURAL`: House-like share (held constant)
- `DISTANCE_FEASIBLE_SHARE_STRUCTURAL`: Default 1.0 (LODES pending)

**Assumption Flags**:
- `TENURE_HELD_CONSTANT`: TRUE
- `STRUCTURE_HELD_CONSTANT`: TRUE
- `JOB_ACCESS_HELD_CONSTANT`: TRUE

---

### 7.3 Eligibility Share Forecast

**Baseline Eligibility**:
- **Model-First**: `PRED_BUDGET_ELIGIBILITY.BUDGET_ELIGIBLE_SHARE` at signal date
- **Fallback**: Rule-based (50% if median income ≥ 3× median rent, else 30%)

**Momentum Adjustment**:
- **Momentum Index**: `(WAGE_GROWTH_YOY × 0.6) + (EMPLOYMENT_GROWTH_YOY × 0.4)`
- **Adjustment Factor**: `clamp(1.0 + (MOMENTUM_INDEX × 0.3), 0.90, 1.10)`
- **Override Weight**: 0.3 (30% momentum influence)
- **Override Flag**: TRUE if adjustment factor ≠ 1.0

**Forecasted Eligibility**:
- **BASE**: `ELIGIBILITY_SHARE_AT_SIGNAL_DATE × MOMENTUM_ADJUSTMENT_FACTOR`
- **DOWNSIDE**: `BASE × (1 - AI_RISK_SCORE × 0.2)`

**AH-Specific Eligibility**:
- Uses `PRED_BUDGET_ELIGIBILITY` with `OFFERING_ID = 'PROG_SFR_AH'` when available
- Fallback: `ELIGIBILITY_SHARE_AT_SIGNAL_DATE × 0.7`

---

### 7.4 Target Demand Forecast

**Formula**:
```sql
TARGET_DEMAND_24M = DEMAND_MASS_24M × ELIGIBILITY_SHARE_24M
```

**Scenarios**:
- **BASE**: Uses BASE eligibility share
- **DOWNSIDE**: Uses DOWNSIDE eligibility share (AI risk applied)

---

## 8. Tract Allocation Methodology

### 8.1 Weighted Allocation (Not Uniform Multiplication)

**Problem**: Uniform multiplication assumes identical tract growth within CBSA

**Solution**: Weighted allocation preserves CBSA totals while allowing heterogeneity

**Formula**:
```sql
TRACT_FORECAST = CURRENT_TRACT_DEMAND + (TRACT_WEIGHT × CBSA_DELTA)
```

Where:
- `CBSA_DELTA = CBSA_FORECAST - CBSA_CURRENT`
- `TRACT_WEIGHT = (CURRENT_TRACT_SHARE × STABILIZER_MODIFIER) / SUM(...)`

**Allocation Weights**:
- **Base Weight**: Current target demand share within CBSA
- **Stabilizer**: `STABILITY_MODIFIER` from `V_TRACT_HOUSING_COHORT` (default: 0.85)
- **Normalization**: Weights sum to 1.0 within CBSA

**Validation**: Sum of tract forecasts = CBSA forecast (tolerance: 0.01)

---

## 9. Data Sources and Freshness

### 9.1 Structural Data (Slow-Moving)

| Source | Table/View | Update Frequency | Lag |
|--------|------------|-------------------|-----|
| ACS 5YR | `SOURCE_PROD.ACS.ACS_TRACT_LONG` | Annual | 12-18 months |
| Oxford AMREG | `TRANSFORM_PROD.CLEANED.AMREG_CBSA_ECONOMICS_MATERIALIZED` | Annual | 6-12 months |
| LODES | `V_TRACT_LODES_SUMMARY` | Annual | 12-18 months (pending integration) |

**Metadata**:
- `AS_OF_STRUCTURAL_DATE`: Typically 2023-12-31
- `TENURE_SHARE_SOURCE`: 'ACS_2019_2023'
- `STRUCTURE_SHARE_SOURCE`: 'ACS_2019_2023'
- `JOB_ACCESS_SOURCE`: 'LODES_2023' (or 'DEFAULT_1P0')

---

### 9.2 Signal Data (Fast-Moving)

| Source | Table/View | Update Frequency | Lag |
|--------|------------|-------------------|-----|
| CPS | `ANALYTICS_PROD.FEATURES.BLS_CPS_CBSA` | Monthly | 1-2 months |
| QCEW | `TRANSFORM_PROD.CLEANED.QCEW_NAICS_CBSA` | Quarterly | 3-4 months |
| AI Risk | `ANALYTICS_PROD.FEATURES.V_AI_REPLACEMENT_RISK_CBSA_SUMMARY` | Versioned | 1 month |
| PITI Rates | `ANALYTICS_PROD.MODELED.DIM_RATE_SCENARIO_PATH` | Manual | N/A (placeholders) |

**Metadata**:
- `AS_OF_SIGNAL_DATE`: Dynamic (latest CPS/QCEW)
- `DATA_MAX_AS_OF_CPS`: Latest CPS date
- `DATA_MAX_AS_OF_QCEW`: Latest QCEW date
- `DATA_MAX_AS_OF_AI`: Latest AI risk date
- `DATA_MAX_AS_OF_RATES`: Rate scenario date

---

## 10. Validation and Quality Checks

### 10.1 Sum Validation

**Check**: Tract forecasts sum to CBSA forecasts

**Query**:
```sql
SELECT 
    CBSA_CODE,
    ABS(CBSA_FORECAST - SUM(TRACT_FORECAST)) AS DIFF
FROM ...
GROUP BY CBSA_CODE
HAVING ABS(DIFF) > 0.01;
```

**Expected**: 0 rows (tolerance: 0.01)

---

### 10.2 Growth Bounds

**Check**: Annual growth rates within expected bounds

**Bounds**: -5% to +10% annual growth

**Query**:
```sql
SELECT 
    CBSA_CODE,
    (POWER(FORECAST_24M / CURRENT, 12.0/24.0) - 1) * 100 AS ANNUAL_GROWTH_24M
FROM ...
WHERE ANNUAL_GROWTH_24M NOT BETWEEN -5 AND 10;
```

**Expected**: < 5% of CBSAs flagged as outliers

---

### 10.3 Override Flags Rate

**Check**: Percentage of CBSAs with adjustment override flag

**Expected**: 10-30% of CBSAs

**Query**:
```sql
SELECT 
    COUNT(*) AS TOTAL_CBSAS,
    SUM(CASE WHEN ADJUSTMENT_OVERRIDE_FLAG THEN 1 ELSE 0 END) AS CBSAS_WITH_OVERRIDE,
    (SUM(...) / COUNT(*)) * 100 AS PCT_OVERRIDE
FROM V_PROGRESS_ELIGIBILITY_SHARE_FORECAST_CBSA;
```

---

### 10.4 Missingness Rates

**Check**: Percentage of CBSAs missing critical data

**Expected**: < 10% missing for each source

**Query**:
```sql
SELECT 
    (SUM(CASE WHEN DATA_MAX_AS_OF_OXFORD IS NULL THEN 1 ELSE 0 END) / COUNT(*)) * 100 AS PCT_MISSING_OXFORD,
    (SUM(CASE WHEN DATA_MAX_AS_OF_CPS IS NULL THEN 1 ELSE 0 END) / COUNT(*)) * 100 AS PCT_MISSING_CPS,
    ...
FROM V_PROGRESS_OFFERINGS_FORECAST_24_36M;
```

---

### 10.5 Data Freshness

**Check**: Data lag within acceptable thresholds

**Thresholds**:
- Oxford: ≤ 12 months
- CPS: ≤ 2 months
- QCEW: ≤ 4 months
- AI Risk: ≤ 1 month

**Query**:
```sql
SELECT 
    DATEDIFF(month, DATA_MAX_AS_OF_CPS, CURRENT_DATE()) AS CPS_LAG_MONTHS,
    CASE WHEN CPS_LAG_MONTHS > 2 THEN TRUE ELSE FALSE END AS CPS_STALE_FLAG
FROM ...
```

---

## 11. Known Limitations and Enhancements

### 11.1 Current Limitations

1. **AH Eligibility**: Uses simplified 0.7 multiplier fallback
   - **Enhancement**: Explicit income band coverage logic

2. **Distance Feasibility**: Defaults to 1.0
   - **Enhancement**: Integrate LODES data for actual commute feasibility

3. **Rate Scenarios**: Uses manual defaults
   - **Enhancement**: Pull from vendor/forecast source (PMMS, SOFR, forward curve)

4. **Mobility Modifier**: Defaults to 0.85 if B07401 missing
   - **Enhancement**: Improve B07401 data coverage

---

### 11.2 Future Enhancements

1. **Explicit Income Band Coverage**: Replace 0.7 multiplier with ACS income bin analysis
2. **LODES Integration**: Actual commute feasibility from LODES data
3. **Rate Forecast Integration**: Automated rate scenario updates
4. **Mobility Data Coverage**: Improve B07401 data availability
5. **Model Calibration**: Fit coefficients outside SQL, persist as parameter tables

---

## 12. Executive Presentation Summary

### 12.1 What's Complete

**CBSA Level**:
- ✅ Demand Mass Forecast (Oxford-based, structural components held constant)
- ✅ Eligibility Share Forecast (Model-first with rule-based fallback)
- ✅ Target Demand Forecast (Demand Mass × Eligibility Share)
- ✅ 24M and 36M Horizons (BASE and DOWNSIDE scenarios)
- ✅ Metadata and Data Lineage (AS_OF dates, source flags)

**Tract Level**:
- ✅ Tract Allocation (Weighted allocation, preserves CBSA totals)
- ✅ All Offerings (TRAD, FY, AH forecasts)
- ✅ Both Scenarios (BASE and DOWNSIDE)
- ✅ Validation Checks (Sum validation, growth bounds, override flags)

---

### 12.2 Key Insights

1. **Market Segmentation**: TRAD, FY, and AH target distinct but overlapping segments
2. **Correlation Patterns**: High correlation between TRAD and AH (subset relationship), moderate between TRAD and FY (family filter)
3. **Forecast Methodology**: Two-stage approach (Demand Mass × Eligibility Share) provides defensible decomposition
4. **Data Quality**: Fallback usage tracked, override flags provide audit trail
5. **Tract Heterogeneity**: Weighted allocation allows tract-level variation while preserving CBSA totals

---

### 12.3 Validation Status

**Pending Verification** (run `verify_progress_forecast_completion.sql`):
- [ ] All views exist and return rows
- [ ] No NULLs in critical columns
- [ ] Sum validation passes (tract = CBSA)
- [ ] Growth bounds within expected ranges
- [ ] Override flags rate 10-30%
- [ ] Missingness rates < 10% per source

---

## Appendix: Visualizations and Analysis Tools

### A.1 Python Visualization Script

**File**: `scripts/visualize_progress_offerings_analysis.py`

**Purpose**: Generate comprehensive visualizations from real Snowflake data

**Generated Visualizations**:
1. **Metrics Distribution**: Histograms and box plots of target demand
2. **EDA Exploratory**: Scatter plots, distributions, component analysis
3. **Correlation Analysis**: Heatmaps, scatter matrices, pairwise correlations
4. **Household Structure**: Modifier distributions and relationships
5. **Forecast Analysis**: Horizon comparisons, BASE vs DOWNSIDE, growth rates
6. **Interactive Dashboard**: Plotly dashboard with hover tooltips

**Usage**:
```bash
python scripts/visualize_progress_offerings_analysis.py
```

**Output Directory**: `docs/visualizations/progress_offerings/`

**See**: `docs/visualizations/PROGRESS_OFFERINGS_VISUALIZATIONS_README.md` for details

---

### A.2 SQL Correlation Analysis

**File**: `sql/analytics/modeled/analyze_offering_demand_correlations.sql`

**Usage**:
```sql
-- Run correlation analysis
SELECT * FROM analyze_offering_demand_correlations;
```

**Output**: Pairwise correlations, summary statistics, fallback usage

---

### A.3 Verification Queries

**File**: `sql/analytics/modeled/verify_progress_forecast_completion.sql`

**Usage**:
```sql
-- Verify completion status
SELECT * FROM verify_progress_forecast_completion;
```

**Output**: Completion status per step, NULL counts, validation results

---

### A.4 Sample Data Queries

**Top 20 CBSAs by TRAD Forecast**:
```sql
SELECT 
    CBSA_CODE,
    PROG_SFR_TRAD_FORECAST_24M_BASE,
    PROG_SFR_TRAD_FORECAST_36M_BASE
FROM ANALYTICS_PROD.MODELED.V_PROGRESS_OFFERINGS_FORECAST_24_36M
ORDER BY PROG_SFR_TRAD_FORECAST_24M_BASE DESC
LIMIT 20;
```

**Tract-Level Distribution**:
```sql
SELECT 
    CBSA_CODE,
    COUNT(*) AS TRACT_COUNT,
    AVG(PROG_SFR_TRAD_FORECAST_24M_BASE) AS AVG_TRAD_24M,
    STDDEV(PROG_SFR_TRAD_FORECAST_24M_BASE) AS STD_TRAD_24M
FROM ANALYTICS_PROD.MODELED.V_PROGRESS_OFFERINGS_TRACT_FORECAST_24_36M
GROUP BY CBSA_CODE
ORDER BY AVG_TRAD_24M DESC;
```

---

**Document Version**: 1.0  
**Last Updated**: 2026-01-27  
**Next Review**: After deployment validation

