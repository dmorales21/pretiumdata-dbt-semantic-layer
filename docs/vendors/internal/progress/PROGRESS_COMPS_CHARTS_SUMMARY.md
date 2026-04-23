# Progress Comps Analysis Charts - Summary

**Date**: 2026-01-27  
**Status**: ✅ **COMPLETE** - Charts generated successfully

---

## Executive Summary

Generated comprehensive charts demonstrating:
1. **Rent Comparison**: Progress ZIP codes vs. Other ZIP codes
2. **Ownership Changes**: Portfolio % changes by institutional ownership size
3. **Business Context**: Connected to dim_offering and dim_opco for business use cases

---

## Charts Generated

### 1. Rent Comparison: Progress ZIP Codes vs Other ZIP Codes

**File**: `output/progress_comps_charts/rent_comparison.html`

**Purpose**: Compare median rental prices in Progress ZIP codes vs. other ZIP codes to understand market positioning.

**Key Metrics**:
- Median rent by ZIP type (Progress vs Other)
- 25th and 75th percentile ranges
- Time series from 2025-06-30 to 2025-11-30

**Data Source**:
- `TRANSFORM_PROD.FACT.HOUSING_HOU_PRICING_ALL_TS`
- Metric: `PARCLLABS_MEDIAN_RENT_NEW_LISTINGS`
- Progress ZIP codes identified from `TRANSFORM_PROD.CLEANED.PROGRESS_PROPERTIES`

**Business Use Case**:
- **Offering Context**: PROG_SFR_TRAD, PROG_SFR_AH, PROG_SFR_FY
- **OpCo**: PROGRESS_RESIDENTIAL
- **Insight**: Compare rent levels in markets where Progress operates vs. broader market to assess pricing strategy effectiveness

---

### 2. Ownership Changes by Portfolio Size

**File**: `output/progress_comps_charts/ownership_changes.html`

**Purpose**: Track changes in institutional ownership by portfolio size category in Progress ZIP codes vs. other markets.

**Key Metrics**:
- % Change in ownership by portfolio size:
  - 100-999 units
  - 1000+ units
  - All portfolios combined
- Comparison: Progress ZIP codes vs. Other ZIP codes

**Data Source**:
- `TRANSFORM_PROD.FACT.HOUSING_HOU_OWNERSHIP_ALL_TS`
- Metrics:
  - `PARCLLABS_OWNERSHIP_PORTFOLIO_100_999_UNITS`
  - `PARCLLABS_OWNERSHIP_PORTFOLIO_1000_PLUS_UNITS`
  - `PARCLLABS_OWNERSHIP_ALL_PORTFOLIO_UNITS`

**Business Use Case**:
- **Offering Context**: All Progress SFR offerings (TRAD, AH, FY)
- **OpCo**: PROGRESS_RESIDENTIAL
- **Insight**: Monitor competitive landscape - are institutional investors increasing presence in Progress markets? How does this compare to broader market trends?

---

### 3. Offering Context: Target IRR Ranges

**File**: `output/progress_comps_charts/offering_context.html`

**Purpose**: Display Progress Residential offerings and their target IRR ranges for business context.

**Key Metrics**:
- Offering names and short codes
- Target IRR ranges (min/max)
- Risk profiles

**Data Source**:
- `ADMIN.CATALOG.DIM_OFFERING` (or default values if table not created)
- `ADMIN.CATALOG.DIM_OPCO`

**Offerings Displayed**:
1. **PROG_SFR_TRAD** (Traditional Cohort)
   - Target IRR: 8-12%
   - Risk: Medium
   
2. **PROG_SFR_AH** (Affordable/HCV Cohort)
   - Target IRR: 6-10%
   - Risk: Low
   
3. **PROG_SFR_FY** (Front Yard Cohort)
   - Target IRR: 9-13%
   - Risk: Medium

**Business Use Case**:
- **OpCo**: PROGRESS_RESIDENTIAL
- **Insight**: Understand offering structure and return expectations when analyzing rent and ownership trends

---

## Data Coverage

### Progress ZIP Codes
- **Total ZIP Codes**: 1,823
- **Source**: `TRANSFORM_PROD.CLEANED.PROGRESS_PROPERTIES`
- **Filter**: IS_OWNED = 1, IS_INACTIVE = 0, IS_DELETED = 0

### Rent Data
- **Time Series**: 6 months (2025-06-30 to 2025-11-30)
- **ZIP Codes with Data**: Progress ZIPs and Other ZIPs
- **Records**: 9 aggregated records

### Ownership Data
- **Time Series**: 22 months (2024-03-01 to 2025-12-01)
- **Geography**: CBSA level (aggregated from ZIP)
- **Records**: 126 ownership change records

---

## Business Use Cases Connected

### Use Case 1: Rent Pricing Strategy Validation

**Question**: Are Progress properties priced competitively in their markets?

**Analysis**:
- Compare median rent in Progress ZIP codes vs. other ZIP codes
- Identify if Progress markets have higher/lower rent levels
- Assess if rent growth trends differ

**Offering Context**:
- **PROG_SFR_TRAD**: Traditional cohort - should align with market median
- **PROG_SFR_AH**: Affordable cohort - should be below market median
- **PROG_SFR_FY**: Front Yard cohort - may be above market median (premium locations)

**OpCo**: PROGRESS_RESIDENTIAL

---

### Use Case 2: Competitive Landscape Monitoring

**Question**: Is institutional ownership increasing in Progress markets?

**Analysis**:
- Track ownership % changes by portfolio size
- Compare Progress ZIP codes vs. other markets
- Identify if larger institutional investors (1000+ units) are entering Progress markets

**Offering Context**:
- All Progress SFR offerings affected by competitive pressure
- Higher institutional ownership may indicate:
  - Market attractiveness (positive)
  - Increased competition (challenge)

**OpCo**: PROGRESS_RESIDENTIAL

---

### Use Case 3: Market Selection for New Acquisitions

**Question**: Which markets have favorable rent levels and manageable institutional competition?

**Analysis**:
- Combine rent comparison and ownership change data
- Identify markets with:
  - Strong rent levels (above median)
  - Stable or declining institutional ownership (less competition)
  - Or: Growing institutional ownership (validates market attractiveness)

**Offering Context**:
- **PROG_SFR_TRAD**: Target markets with stable rent growth
- **PROG_SFR_FY**: Target markets with premium rent potential
- **PROG_SFR_AH**: Target markets with affordability focus

**OpCo**: PROGRESS_RESIDENTIAL

---

## Comps Engine Review

### Current Comps Framework

**Primary Source**: Parcl Labs API
- Real-time property search
- Institutional investor rentals
- Progressive fallback strategy (5 tiers)

**Fallback Sources**:
- Zonda Floorplans (BTR rent data)
- Zonda Comprehensive (broader market data)

**Coverage**: 60-80% via API, 100% with fallbacks

### Integration with Charts

The charts complement the comps engine by providing:
1. **Historical Context**: FACT table data shows trends over time (API is real-time only)
2. **Market-Level Analysis**: Aggregated ZIP/CBSA level data for portfolio decisions
3. **Competitive Intelligence**: Ownership changes show competitive dynamics

---

## Files Created

1. **Script**: `scripts/generate_progress_comps_charts.py`
   - Generates all three charts
   - Connects to dim_offering and dim_opco
   - Handles missing tables gracefully

2. **Charts**:
   - `output/progress_comps_charts/rent_comparison.html`
   - `output/progress_comps_charts/ownership_changes.html`
   - `output/progress_comps_charts/offering_context.html`
   - `output/progress_comps_charts/index.html`

3. **Documentation**: This file

---

## Next Steps

### Enhancements

1. **Add Offering-Specific Analysis**:
   - Segment Progress ZIP codes by offering (TRAD, AH, FY)
   - Compare rent and ownership by offering type

2. **Add OpCo Comparison**:
   - Compare Progress vs. Imagine Homes markets
   - Cross-OpCo competitive analysis

3. **Add Property-Level Comps**:
   - Use comps engine to get actual comps for Progress properties
   - Compare Progress rent vs. comp median rent
   - Map to offerings for validation

4. **Add Geographic Mapping**:
   - Map charts to CBSA/market level
   - Show geographic distribution of rent differences
   - Overlay ownership changes on map

---

## Usage

### View Charts

```bash
# Open in browser
open output/progress_comps_charts/index.html
```

### Regenerate Charts

```bash
python3 scripts/generate_progress_comps_charts.py
```

### Customize Analysis

Edit `scripts/generate_progress_comps_charts.py` to:
- Change date ranges
- Add additional metrics
- Filter by specific offerings
- Add geographic filters

---

## Summary

✅ **Charts Generated**: 3 comprehensive charts  
✅ **Data Sources**: FACT tables (rent, ownership), DIM_OFFERING, DIM_OPCO  
✅ **Business Context**: Connected to Progress offerings and OpCo structure  
✅ **Comps Integration**: Complements real-time comps engine with historical/aggregated analysis  

**Status**: Ready for business use case analysis

---

**Last Updated**: 2026-01-27

