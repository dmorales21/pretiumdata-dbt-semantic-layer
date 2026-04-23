# Progress Offerings: Demand Pattern Analysis & Research Questions

**Date**: 2026-01-27  
**Data Sources**: CBSA and Tract-level demand analysis  
**Purpose**: Deep analysis of relationships and research questions for uncovering demand patterns and growth rankings

---

## Executive Summary

### Key Findings

1. **CBSA-Level Correlations**: Extremely high correlation between offerings (TRAD↔FY: 0.999, TRAD↔AH: 0.896, FY↔AH: 0.910)
   - **Implication**: At market level, offerings move together - suggests structural drivers dominate

2. **Tract-Level Correlations**: Moderate correlation between TRAD↔FY (0.884), weak with AH (0.12-0.25)
   - **Implication**: Tract-level heterogeneity exists - AH may have different drivers than TRAD/FY

3. **Counterintuitive Negative Correlations**: Base renters and "can afford" metrics negatively correlate with target demand at tract level
   - **Implication**: Demand is not simply "more renters = more demand" - affordability filters are complex

4. **High Variance**: Standard deviation >> mean for all offerings (CBSA: std=18,434 vs mean=3,035 for TRAD)
   - **Implication**: Highly skewed distribution - few markets drive most demand

5. **Zero-Demand Tracts**: 50th percentile is 0 for all offerings at tract level
   - **Implication**: Most tracts have no demand - demand is highly concentrated

---

## 1. Demand Pattern Analysis

### 1.1 CBSA-Level Patterns

**Distribution Characteristics**:
- **TRAD**: Mean=3,035, Median=1,246, Max=532,676 (top market: 175x median)
- **FY**: Mean=1,155, Median=465, Max=203,000 (top market: 437x median)
- **AH**: Mean=1,012, Median=408, Max=195,000 (top market: 478x median)

**Key Observations**:
1. **Extreme Concentration**: Top 10% of markets likely account for 50%+ of total demand
2. **Offering Alignment**: Near-perfect correlation suggests same structural factors drive all offerings
3. **Scale Effects**: Larger markets (more renters) = more demand, but relationship is non-linear

**Research Questions**:

**RQ1.1**: What structural factors explain the extreme concentration of demand in top markets?
- Hypothesis: Population size, renter share, and affordability interact non-linearly
- Analysis: Quantile regression to identify breakpoints where demand accelerates
- Data needed: Population, renter share, median income, median rent by CBSA

**RQ1.2**: Why do TRAD, FY, and AH move in near-perfect lockstep at CBSA level but diverge at tract level?
- Hypothesis: CBSA-level aggregates mask tract-level heterogeneity; AH has different affordability thresholds
- Analysis: Decompose CBSA correlation into tract-level components; identify tracts where AH diverges
- Data needed: Tract-level affordability bands, income distribution, rent burden

**RQ1.3**: What is the optimal market size for Progress offerings?
- Hypothesis: Diminishing returns beyond certain market size; mid-size markets may have better yield
- Analysis: Demand per renter household by market size quintiles; identify "sweet spot" markets
- Data needed: Market size tiers, demand per capita metrics

### 1.2 Tract-Level Patterns

**Distribution Characteristics**:
- **TRAD**: Mean=32.1, Median=0, Max=1,886 (99th percentile likely >500)
- **FY**: Mean=12.2, Median=0, Max=566 (99th percentile likely >200)
- **AH**: Mean=6.7, Median=0, Max=1,185 (99th percentile likely >150)

**Key Observations**:
1. **Sparse Demand**: Most tracts have zero demand - demand is highly localized
2. **AH Divergence**: AH correlation with TRAD/FY is weak (0.12-0.25) - different drivers
3. **Negative Base Correlations**: More base renters doesn't predict more target demand

**Research Questions**:

**RQ2.1**: What tract characteristics predict non-zero demand?
- Hypothesis: Job access, household structure, affordability bands, not just renter count
- Analysis: Logistic regression (demand > 0 vs = 0) with tract features
- Data needed: LODES job access, household structure modifiers, income distribution, rent burden

**RQ2.2**: Why does AH demand diverge from TRAD/FY at tract level?
- Hypothesis: AH targets different income bands; may be more sensitive to rent burden or subsidy availability
- Analysis: Compare income distribution and rent burden in high-AH vs high-TRAD tracts
- Data needed: Tract-level income distribution (B19001), rent burden (B25070), subsidy indicators

**RQ2.3**: What explains the negative correlation between base renters and target demand?
- Hypothesis: High renter tracts may have lower affordability; demand filters are more restrictive
- Analysis: Stratify by affordability bands; examine demand conversion rates by renter density
- Data needed: Affordability conversion rates, renter density, median income/rent

**RQ2.4**: How do household structure modifiers (children, stability, house-like share) affect demand?
- Hypothesis: FY demand should correlate with children modifier; TRAD with mainstream share
- Analysis: Correlation analysis between modifiers and offering-specific demand
- Data needed: Household structure modifiers from V_TRACT_HOUSING_COHORT

---

## 2. Growth Ranking Research Questions

### 2.1 Current Demand vs Growth Potential

**Key Insight**: High current demand doesn't necessarily predict growth - need forward-looking indicators

**Research Questions**:

**RQ3.1**: Which markets have high current demand but low growth potential (saturated)?
- Hypothesis: Markets with high demand but low employment/wage growth, high rent growth, low permits
- Analysis: Rank markets by current demand, then by growth indicators; identify divergence
- Data needed: Employment growth (QCEW), wage growth (CPS/QCEW), rent growth (MLS/Zillow), permits (BPS)

**RQ3.2**: Which markets have low current demand but high growth potential (emerging)?
- Hypothesis: Markets with population growth, employment growth, but not yet reflected in demand
- Analysis: Identify markets with positive economic momentum but low current demand
- Data needed: Population growth (Oxford/ACS), employment growth, household formation rates

**RQ3.3**: How do economic fundamentals (wage growth, employment growth) predict demand growth?
- Hypothesis: Wage growth > employment growth for affordability; employment growth > wage growth for volume
- Analysis: Regression of demand growth on economic indicators with lags
- Data needed: Historical demand data, wage/employment growth time series, lag analysis

### 2.2 Market Maturity and Lifecycle

**Research Questions**:

**RQ4.1**: Can we identify market lifecycle stages (emerging, growth, mature, saturated)?
- Hypothesis: Emerging = low demand + high growth; Growth = medium demand + high growth; Mature = high demand + low growth; Saturated = high demand + negative growth
- Analysis: Cluster analysis using demand level and growth indicators
- Data needed: Current demand, growth indicators, time series for trend analysis

**RQ4.2**: What is the optimal entry point in a market lifecycle?
- Hypothesis: Entry during "growth" stage maximizes returns; "emerging" has risk, "mature" has competition
- Analysis: Compare returns/yields by lifecycle stage (if available) or proxy with absorption rates
- Data needed: Historical performance data, absorption rates, competition metrics

**RQ4.3**: How do supply constraints (permits, inventory) affect demand growth?
- Hypothesis: Low supply + high demand = price/rent growth = affordability pressure = demand destruction
- Analysis: Interaction between permit levels, inventory, and demand growth
- Data needed: Building permits (BPS), inventory levels (MLS/Zillow), rent growth

### 2.3 Competitive Positioning

**Research Questions**:

**RQ5.1**: Which markets have favorable demand-to-competition ratios?
- Hypothesis: High demand + low competition (permits, inventory) = better positioning
- Analysis: Demand per unit of competition (permits, active listings)
- Data needed: Demand metrics, building permits, active listings, absorption rates

**RQ5.2**: How does existing Progress footprint affect demand patterns?
- Hypothesis: Markets with existing footprint may have different demand patterns (brand recognition, operational efficiency)
- Analysis: Compare demand patterns in markets with vs without existing footprint
- Data needed: Progress portfolio locations, demand metrics by market

**RQ5.3**: What is the optimal market concentration strategy?
- Hypothesis: Concentrated markets (few high-demand CBSAs) vs diversified (many medium-demand CBSAs)
- Analysis: Portfolio optimization using demand variance, correlation, and growth indicators
- Data needed: Demand metrics across markets, correlation matrix, growth forecasts

---

## 3. Affordability and Eligibility Patterns

### 3.1 Affordability Thresholds

**Key Insight**: "Can afford" metric negatively correlates with target demand - suggests affordability filters are complex

**Research Questions**:

**RQ6.1**: What income-to-rent ratios predict demand for each offering?
- Hypothesis: TRAD: 3.0-4.0x; FY: 3.5-4.5x (higher for families); AH: 2.0-3.0x (lower threshold)
- Analysis: Analyze demand by income-to-rent ratio bands for each offering
- Data needed: Tract-level income distribution, median rent, demand by offering

**RQ6.2**: How does rent burden (rent as % of income) affect demand?
- Hypothesis: High rent burden (>30%) reduces demand even if "can afford" threshold is met
- Analysis: Demand by rent burden bands; interaction with income levels
- Data needed: Rent burden distribution (B25070), demand metrics

**RQ6.3**: What is the optimal affordability band for each offering?
- Hypothesis: TRAD: middle-income; FY: middle-to-upper-middle (families); AH: lower-middle
- Analysis: Demand density by income quintiles for each offering
- Data needed: Income distribution, demand by offering

### 3.2 Eligibility Share Dynamics

**Research Questions**:

**RQ7.1**: How does eligibility share vary by market characteristics?
- Hypothesis: Higher wage growth markets have higher eligibility; high rent growth markets have lower eligibility
- Analysis: Regression of eligibility share on economic and housing market indicators
- Data needed: Eligibility share (from forecast views), wage growth, rent growth, unemployment

**RQ7.2**: What drives eligibility share changes over time?
- Hypothesis: Wage growth, rent growth, unemployment, PITI rates all affect eligibility
- Analysis: Time series analysis of eligibility share with economic indicators
- Data needed: Historical eligibility share, economic time series

**RQ7.3**: How does AI replacement risk affect eligibility share?
- Hypothesis: High AI risk markets have lower eligibility share (wage pressure, job loss risk)
- Analysis: Correlation between AI risk scores and eligibility share
- Data needed: AI risk scores by CBSA, eligibility share metrics

---

## 4. Household Structure and Demand Drivers

### 4.1 Offering-Specific Drivers

**Research Questions**:

**RQ8.1**: How do household structure modifiers predict offering-specific demand?
- Hypothesis: 
  - TRAD: RENTER_MAINSTREAM_SHARE (renter share × house-like share)
  - FY: RENTER_FAMILY_SIZE_SHARE × CHILDREN_MODIFIER × STABILITY_MODIFIER
  - AH: RENTER_HOUSELIKE_SHARE × affordability-first filter
- Analysis: Regression of demand on modifiers with interaction terms
- Data needed: Household structure modifiers, demand by offering

**RQ8.2**: What is the optimal household structure profile for each offering?
- Hypothesis: TRAD: single/couples, no children; FY: families with children, stable; AH: any structure, affordability-first
- Analysis: Cluster analysis of tracts by household structure and demand patterns
- Data needed: Household structure data, demand metrics

**RQ8.3**: How does mobility (stability modifier) affect FY demand?
- Hypothesis: Higher stability (lower mobility) = higher FY demand (families prefer stability)
- Analysis: Correlation and regression of FY demand on stability modifier
- Data needed: Stability modifier, FY demand

### 4.2 Spatial and Job Access Patterns

**Research Questions**:

**RQ9.1**: How does job access (LODES) affect demand?
- Hypothesis: Higher job access = higher demand (work nearby filter)
- Analysis: Correlation between job access metrics and demand
- Data needed: LODES job access data, demand metrics

**RQ9.2**: What is the optimal job access threshold for demand?
- Hypothesis: Demand increases up to a threshold, then plateaus (diminishing returns)
- Analysis: Demand by job access quintiles; identify threshold
- Data needed: Job access metrics, demand data

**RQ9.3**: How do commute patterns affect demand?
- Hypothesis: Shorter commutes = higher demand (quality of life, affordability)
- Analysis: Demand by commute time bands
- Data needed: Commute time data (B08303), demand metrics

---

## 5. Forecast and Scenario Analysis

### 5.1 Forecast Accuracy and Validation

**Research Questions**:

**RQ10.1**: How accurate are the 24M and 36M forecasts?
- Hypothesis: Forecast accuracy varies by market size, economic volatility, data quality
- Analysis: Compare forecasted vs actual demand (when available) by market characteristics
- Data needed: Historical forecasts, actual demand data, market characteristics

**RQ10.2**: Which markets have the highest forecast uncertainty?
- Hypothesis: Markets with volatile economic indicators, missing data, or extreme values
- Analysis: Forecast variance by market; identify high-uncertainty markets
- Data needed: Forecast scenarios (BASE vs DOWNSIDE), data quality flags

**RQ10.3**: How do BASE vs DOWNSIDE scenarios differ by market?
- Hypothesis: Markets with high AI risk, high unemployment, or high rent growth have larger BASE-DOWNSIDE gaps
- Analysis: Compare BASE-DOWNSIDE gaps by market characteristics
- Data needed: BASE and DOWNSIDE forecasts, market characteristics

### 5.2 Growth Scenario Ranking

**Research Questions**:

**RQ11.1**: Which markets rank highest for growth under BASE scenario?
- Hypothesis: Markets with high current demand + positive economic momentum
- Analysis: Rank markets by 24M/36M forecast growth rates under BASE scenario
- Data needed: Current demand, 24M/36M BASE forecasts

**RQ11.2**: Which markets are most resilient (small BASE-DOWNSIDE gap)?
- Hypothesis: Markets with diversified economies, low AI risk, stable employment
- Analysis: Rank markets by BASE-DOWNSIDE gap (smaller = more resilient)
- Data needed: BASE and DOWNSIDE forecasts

**RQ11.3**: Which markets have highest upside potential (large BASE-DOWNSIDE gap but positive BASE)?
- Hypothesis: Markets with high current demand but economic uncertainty (volatile but positive)
- Analysis: Identify markets with high BASE forecast but large DOWNSIDE risk
- Data needed: BASE and DOWNSIDE forecasts, economic indicators

---

## 6. Implementation Priorities

### High Priority Research Questions (Immediate Action)

1. **RQ1.1**: Structural factors explaining demand concentration (quantile regression)
2. **RQ3.1**: Saturated markets identification (current demand vs growth indicators)
3. **RQ3.2**: Emerging markets identification (low demand + high growth)
4. **RQ5.1**: Demand-to-competition ratios (competitive positioning)
5. **RQ11.1**: Growth ranking under BASE scenario (immediate ranking need)

### Medium Priority Research Questions (Next Phase)

1. **RQ2.1**: Tract characteristics predicting non-zero demand (logistic regression)
2. **RQ4.1**: Market lifecycle stages (cluster analysis)
3. **RQ6.1**: Income-to-rent ratios by offering (affordability thresholds)
4. **RQ8.1**: Household structure modifiers predicting demand (regression)
5. **RQ10.1**: Forecast accuracy validation (when data available)

### Lower Priority Research Questions (Exploratory)

1. **RQ1.2**: TRAD/FY/AH divergence at tract level (decomposition analysis)
2. **RQ2.2**: AH divergence drivers (income distribution analysis)
3. **RQ7.1**: Eligibility share variation (regression analysis)
4. **RQ9.1**: Job access effects (correlation analysis)

---

## 7. Data Requirements Summary

### Critical Data Gaps

1. **Economic Indicators**:
   - Wage growth (CPS/QCEW) - Available but needs integration
   - Employment growth (QCEW) - Available but needs integration
   - Population growth (Oxford/ACS) - Available but needs integration

2. **Housing Market Indicators**:
   - Rent growth (MLS/Zillow) - Available but needs integration
   - Building permits (BPS) - Available but needs integration
   - Inventory levels (MLS/Zillow) - Available but needs integration

3. **Household Structure**:
   - Modifiers from V_TRACT_HOUSING_COHORT - Available but needs integration
   - Income distribution (B19001) - Available but needs integration
   - Rent burden (B25070) - Available but needs integration

4. **Forecast Components**:
   - Eligibility share forecasts - Available in forecast views
   - Demand mass forecasts - Available in forecast views
   - AI risk scores - Available but needs integration

### Recommended Next Steps

1. **Create Integrated Analysis View**: Combine demand metrics with economic indicators, housing market data, and household structure
2. **Build Growth Ranking Model**: Integrate current demand, growth indicators, and forecast scenarios
3. **Develop Market Segmentation**: Cluster markets by lifecycle stage, competitive position, and growth potential
4. **Validate Forecasts**: Compare forecasted vs actual when historical data becomes available

---

## 8. Analytical Framework

### Ranking Methodology

**Proposed Growth Ranking Formula**:
```
Growth_Score = 
  (Current_Demand_Score × 0.3) +
  (Economic_Momentum_Score × 0.3) +
  (Forecast_Growth_Score × 0.2) +
  (Competitive_Position_Score × 0.2)
```

Where:
- **Current_Demand_Score**: Normalized current demand (log scale to handle skew)
- **Economic_Momentum_Score**: Weighted average of wage growth, employment growth, population growth
- **Forecast_Growth_Score**: 24M/36M forecast growth rates (BASE scenario)
- **Competitive_Position_Score**: Demand per unit of competition (permits, inventory)

### Market Segmentation Framework

**Four-Quadrant Matrix**:
- **X-axis**: Current Demand (Low vs High)
- **Y-axis**: Growth Potential (Low vs High)

**Quadrants**:
1. **Emerging** (Low Demand, High Growth): Entry opportunity, high risk/reward
2. **Growth** (High Demand, High Growth): Optimal target, balanced risk/reward
3. **Mature** (High Demand, Low Growth): Stable cash flow, low growth
4. **Declining** (Low Demand, Low Growth): Avoid or exit

---

## Conclusion

The analysis reveals that demand patterns are highly concentrated, offerings are highly correlated at CBSA level but diverge at tract level, and growth potential requires forward-looking indicators beyond current demand. The research questions outlined above provide a roadmap for uncovering demand patterns and developing growth rankings that integrate structural, economic, and forecast components.

**Next Action**: Prioritize RQ1.1, RQ3.1, RQ3.2, RQ5.1, and RQ11.1 for immediate implementation to build the growth ranking framework.

