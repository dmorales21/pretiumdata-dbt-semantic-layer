# Progress Presentation Charts - Implementation Summary

**Date**: 2026-01-27  
**Status**: Charts planned and initial implementation created

---

## Overview

This document summarizes the chart planning and implementation for Progress presentation concepts using STRATA visualization style.

---

## Chart Implementation Status

### ✅ Implemented (High Priority)

1. **Chart 1.1: Cost to Own vs. Cost to Rent** (Stacked Area Chart)
   - **File**: `scripts/generate_progress_presentation_charts.py` → `chart_1_1_cost_to_own_vs_rent()`
   - **Status**: ✅ Implemented
   - **Data Sources**: 
     - `TRANSFORM_PROD.FACT.HOUSING_HOU_PRICING_ALL_TS` (ZORI rent)
     - `TRANSFORM_PROD.FACT.HOUSING_HOU_ASSET_ALL_TS` (ZHVI home values)
   - **Output**: `output/progress_presentation_charts/1_1_cost_to_own_vs_rent.html`

2. **Chart 1.2: Owner vs Renter Income** (Grouped Bar Chart)
   - **File**: `scripts/generate_progress_presentation_charts.py` → `chart_1_2_owner_vs_renter_income()`
   - **Status**: ✅ Implemented
   - **Data Sources**: `TRANSFORM_PROD.FACT.FACT_ACS_CBSA_TS` (ACS income data)
   - **Output**: `output/progress_presentation_charts/1_2_owner_vs_renter_income.html`

3. **Chart 1.3: Rent vs Own Cost Gap** (Multi-line Chart)
   - **File**: `scripts/generate_progress_presentation_charts.py` → `chart_1_3_rent_vs_own_cost_gap()`
   - **Status**: ✅ Implemented
   - **Data Sources**: Same as Chart 1.1
   - **Output**: `output/progress_presentation_charts/1_3_rent_vs_own_cost_gap.html`

4. **Chart 1.6: Effective Rent vs Market Rent** (Scatter Plot)
   - **File**: `scripts/generate_progress_presentation_charts.py` → `chart_1_6_effective_vs_market_rent()`
   - **Status**: ✅ Implemented
   - **Data Sources**: `TRANSFORM_PROD.CLEANED.PROGRESS_PROPERTIES` (RENT_CURRENT, RENT_MARKET)
   - **Output**: `output/progress_presentation_charts/1_6_effective_vs_market_rent.html`

5. **Chart 8.1: Institutional Ownership Over Time** (Multi-line Chart)
   - **File**: `scripts/generate_progress_presentation_charts.py` → `chart_8_1_institutional_ownership_over_time()`
   - **Status**: ✅ Implemented
   - **Data Sources**: `TRANSFORM_PROD.FACT.HOUSING_HOU_OWNERSHIP_ALL_TS` (Parcl Labs data)
   - **Output**: `output/progress_presentation_charts/8_1_institutional_ownership_over_time.html`

6. **Chart 8.2: Portfolio Size Distribution** (Donut Chart)
   - **File**: `scripts/generate_progress_presentation_charts.py` → `chart_8_2_portfolio_size_distribution()`
   - **Status**: ✅ Implemented
   - **Data Sources**: Same as Chart 8.1
   - **Output**: `output/progress_presentation_charts/8_2_portfolio_size_distribution.html`

### ⚠️ Planned (Not Yet Implemented)

7. **Chart 1.4: Owner Burden vs Renter Burden** (Stacked Bar Chart)
   - **Status**: ⚠️ Planned
   - **Data Sources**: `ANALYTICS_PROD.MODELED.V_TRACT_HOUSING_COHORT` (rent burden brackets)
   - **Priority**: High

8. **Chart 1.5: Renter Income Distribution by Bracket** (Stacked Bar Chart)
   - **Status**: ⚠️ Planned
   - **Data Sources**: `TRANSFORM_PROD.FACT.FACT_ACS_ZIP_TS` (B19001 income brackets)
   - **Priority**: High

9. **Chart 2.1: Work Order Response Time** (Violin Plot)
   - **Status**: ⚠️ Planned
   - **Data Sources**: `DS_SOURCE_PROD_SFDC.SFDC_SHARE.CASE` (work order timestamps)
   - **Priority**: Medium

10. **Chart 2.2: Emergency Work Orders % Resolved** (Horizontal Bar Chart)
    - **Status**: ⚠️ Planned
    - **Data Sources**: `TRANSFORM_PROD.CLEANED.PROGRESS_MAINTENANCE_EVENTS`
    - **Priority**: Medium

11. **Chart 3.1: Unit Size Distribution** (Overlaid Histogram)
    - **Status**: ⚠️ Planned
    - **Data Sources**: `TRANSFORM_PROD.CLEANED.PROGRESS_PROPERTIES` (SQUARE_FEET)
    - **Priority**: Medium

12. **Chart 3.2: Bedroom Distribution** (Grouped Bar Chart)
    - **Status**: ⚠️ Planned
    - **Data Sources**: `TRANSFORM_PROD.CLEANED.PROGRESS_PROPERTIES` (BEDROOMS)
    - **Priority**: Medium

13. **Chart 5.1: Owner Costs Over Time** (Stacked Bar Chart)
    - **Status**: ⚠️ Planned
    - **Data Sources**: Same as Chart 1.1
    - **Priority**: High

14. **Chart 5.4: Single-Family Supply Reduction** (Dual-Axis Line Chart)
    - **Status**: ⚠️ Planned
    - **Data Sources**: `TRANSFORM_PROD.FACT.HOUSING_HOU_INVENTORY_ALL_TS` (SFR supply metrics)
    - **Priority**: High

15. **Chart 7.1: Tenant Income Distribution (Internal vs Public)** (Overlaid Histogram)
    - **Status**: ⚠️ Planned
    - **Data Sources**: 
      - Internal: `DS_SOURCE_PROD_SFDC.SFDC_SHARE.*` (Salesforce tenant data)
      - Public: `TRANSFORM_PROD.FACT.FACT_ACS_ZIP_TS` (ACS ZIP-level data)
    - **Priority**: High
    - **Note**: Requires Salesforce schema exploration

16. **Chart 7.2: FICO Score Distribution** (Histogram)
    - **Status**: ⚠️ Planned
    - **Data Sources**: `DS_SOURCE_PROD_SFDC.SFDC_SHARE.LEASE_APPLICATION__C` (credit scores)
    - **Priority**: High
    - **Note**: Requires Salesforce schema exploration

17. **Chart 9.1: Working People Location Map** (Choropleth + Scatter)
    - **Status**: ⚠️ Planned
    - **Data Sources**: 
      - `ANALYTICS_PROD.MODELED.V_TRACT_LODES_SUMMARY` (job density)
      - `TRANSFORM_PROD.CLEANED.PROGRESS_PROPERTIES` (property locations)
    - **Priority**: Medium
    - **Note**: Requires map visualization (MapLibre or Plotly mapbox)

18. **Chart 10.1: Institutional Capacity vs Market Size** (Scatter Plot)
    - **Status**: ⚠️ Planned
    - **Data Sources**: Same as Chart 8.1
    - **Priority**: Medium

19. **Chart 12.1: Future Income Forecast** (Line Chart with Confidence Bands)
    - **Status**: ⚠️ Planned
    - **Data Sources**: `TRANSFORM_PROD.CLEANED.AMREG_CBSA_ECONOMICS_MATERIALIZED` (forecasts)
    - **Priority**: Medium

20. **Chart 13.1: Maintenance Capacity at Scale** (Scatter Plot)
    - **Status**: ⚠️ Planned
    - **Data Sources**: 
      - `TRANSFORM_PROD.CLEANED.PROGRESS_MAINTENANCE_EVENTS` (maintenance costs)
      - `TRANSFORM_PROD.CLEANED.PROGRESS_PROPERTIES` (portfolio size)
    - **Priority**: Medium

---

## Chart Type Evaluation

### ✅ Best Chart Types Selected

1. **Stacked Area/Bar Charts**: Selected for component breakdowns (costs, burdens, supply)
   - **Rationale**: Shows total and composition simultaneously
   - **Alternatives Considered**: Line charts (less clear for composition)

2. **Multi-line Charts**: Selected for time series comparisons
   - **Rationale**: Shows trends and relationships between metrics
   - **Alternatives Considered**: Bar charts (loses trend smoothness)

3. **Scatter Plots**: Selected for relationships and distributions
   - **Rationale**: Shows property-level granularity and correlations
   - **Alternatives Considered**: Bar charts (loses detail)

4. **Horizontal Bar Charts**: Selected for market comparisons
   - **Rationale**: Easier to read market names
   - **Alternatives Considered**: Vertical bars (names harder to read)

5. **Donut Charts**: Selected for composition (portfolio sizes)
   - **Rationale**: Shows composition with center space for annotations
   - **Alternatives Considered**: Pie charts (less space for annotations)

6. **Overlaid Histograms**: Selected for distribution comparisons
   - **Rationale**: Shows distribution shape and differences
   - **Alternatives Considered**: Box plots (loses distribution detail)

### ❌ Alternatives Rejected

- **Too many line charts**: Use stacked/grouped bars for composition data
- **Vertical bars for markets**: Horizontal better for readability
- **Pie charts**: Donut better for composition with annotations
- **Simple bar charts**: Use scatter plots when property-level detail is valuable

---

## STRATA Style Implementation

### Color Usage

- **Primary Data**: `ui_accent` (#327ca3 - Blue)
- **Positive/Verified**: `verified` (#1E4022 - Deep Hunter Green)
- **Neutral/Stable**: `stable` (#2D3F5F - Slate Blue)
- **Warning/Watch**: `watch` (#C9A227 - Golden Ochre)
- **Concern/Issue**: `concern` (#B7352C - Brick Red)
- **Background**: `surface` (#FDFDFE - White)
- **Text**: `text_primary` (#2E2E33 - Graphite Gray)

### Typography

- **Font Family**: `system-ui, -apple-system, sans-serif`
- **Font Sizes**: 
  - Titles: 14-16px
  - Labels: 11-12px
  - Tick labels: 10px

### Chart Styling

- **Background**: White (`surface`)
- **Grid**: Light gray (`border` color with low opacity)
- **Hover**: Unified hover mode for time series
- **Markers**: Size 4-8px depending on chart type
- **Line Width**: 2-3px for primary lines, 1-2px for secondary

---

## Usage Instructions

### Generate Charts

```bash
cd /Users/aposes/Documents/STRATA
python scripts/generate_progress_presentation_charts.py
```

### Output Location

Charts are saved to: `output/progress_presentation_charts/`

- Individual HTML files: `{chart_name}.html`
- Index file: `index.html` (view all charts in one page)

### View Charts

1. Open `output/progress_presentation_charts/index.html` in a web browser
2. Or open individual chart HTML files directly

---

## Next Steps

1. **Execute Script**: Run the chart generation script to create initial charts
2. **Verify Data**: Check that all data sources are accessible and have sufficient data
3. **Implement Remaining Charts**: Add remaining high-priority charts (1.4, 1.5, 5.1, 5.4, 7.1, 7.2)
4. **Salesforce Schema Exploration**: Explore Salesforce schema for tenant-level data (FICO, pets, kids)
5. **Map Visualizations**: Implement map-based charts (9.1) using MapLibre or Plotly mapbox
6. **Refinement**: Adjust colors, labels, and formatting based on review

---

## Data Requirements Checklist

### ✅ Available Data Sources

- [x] Zillow ZORI rent data
- [x] Zillow ZHVI home value data
- [x] ACS income data (owner/renter)
- [x] Institutional ownership data (Parcl Labs)
- [x] Progress properties data (rent, size, bedrooms)

### ⚠️ Needs Verification

- [ ] Salesforce tenant application data (FICO, income, pets, kids)
- [ ] Work order response time data (Salesforce CASE table)
- [ ] Maintenance cost data (aggregated)
- [ ] AMREG income forecasts
- [ ] LODES job accessibility data

### ❌ Missing Data Sources

- [ ] Student loan debt data
- [ ] Disaster relief response data
- [ ] Alternative loan product data (Deephaven/Selene)
- [ ] Health outcomes data (CDC)

---

**Last Updated**: 2026-01-27  
**Implementation Status**: 6 charts implemented, 14+ charts planned

