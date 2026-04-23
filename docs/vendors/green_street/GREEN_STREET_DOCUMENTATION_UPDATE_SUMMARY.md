# Green Street Documentation Update Summary
**Date**: 2026-01-31  
**Status**: ✅ **COMPLETE** - Definitions Updated  
**Purpose**: Summary of Green Street definitions added to governance tables

---

## Updates Applied

### ✅ DIM_METRIC Updated
**Metrics**: All Green Street metrics (pattern: `GREEN_STREET_*`, `MACRO_RATES_MONTHLY_*`)

**Description Pattern**: Based on [Green Street Data Dictionary](file://GreenStreet-Data-Dictionary.pdf)

**Key Metric Categories**:
- **Market and Economic Metrics**: Cap rates, NOI estimates, asset values, rent metrics, occupancy rates
- **Household Income Metrics**: HHI_3mi, HHI_7mi, HHI_10mi, HHI_mean variants
- **Population and Household Metrics**: Population counts, household counts within radius
- **Property Metrics**: GLA, stores, year built, year acquired, year renovation
- **Market Scores**: TAP score, LDC Health Index scores, rating scores
- **Vacancy Metrics**: Vacancy rates, long-term vacant units
- **Education Metrics**: College degree percentages
- **Sales Metrics**: Sales per square foot
- **Macro Indicators**: Interest rates, personal income, employment, PCE, unemployment, housing starts, stock metrics

**Example Descriptions**:
- `GREEN_STREET_CAP_RATE` → "Cap rate estimate. A cap rate primarily used to reflect market cap-ex assumptions, calculated as: NOI less a standardized market capex reserve divided by the property value. Data from Green Street Advisors..."
- `GREEN_STREET_HHI_3MI` → "Median household income within a 3-mile radius. Data from Green Street Advisors..."
- `MACRO_RATES_MONTHLY_INTEREST_RATE` → "Interest rate or market rate indicator. Data from Green Street Advisors..."

---

### ✅ DIM_DATASET Updated
**Dataset**: `MACRO_RATES_MONTHLY`

**Description Added**:
> Green Street Advisors market data and analytics. Green Street is a leading provider of commercial real estate research, analytics, and advisory services. The MACRO_RATES_MONTHLY dataset contains monthly macroeconomic indicators, interest rates, cap rates, and market metrics for commercial real estate analysis. Data includes property valuations, market occupancy rates, rent metrics, household income data, population demographics, and market health scores. Green Street provides comprehensive coverage of U.S. retail, office, industrial, and multifamily real estate markets with proprietary analytics and market intelligence.

---

### ✅ DIM_VENDOR Updated
**Vendor**: `GREEN_STREET`

**Description Added**:
> Green Street Advisors is a leading provider of commercial real estate research, analytics, and advisory services. Green Street provides comprehensive coverage of U.S. retail, office, industrial, and multifamily real estate markets with proprietary analytics, market intelligence, and valuation models. Services include property-level data, market analytics, cap rate estimates, NOI estimates, trade area analysis, and market health scores. Green Street's data dictionary includes metrics for property characteristics, market demographics, occupancy rates, rent metrics, and proprietary scoring systems for market health and trade area strength.

---

## Source Information

### Green Street Data Dictionary
- **Source**: [GreenStreet-Data-Dictionary.pdf](file://GreenStreet-Data-Dictionary.pdf)
- **Location**: 100 Bayview Circle, Suite 400, Newport Beach, CA 92660
- **Contact**: ClientSupport@GreenStreet.com
- **Website**: my.greenstreet.com

### Key Data Categories from Dictionary
1. **U.S. Retail Databases**: Property-level data, owner information, tenant data
2. **Retail Analytics Pro**: Market analytics, vacancy rates, unit counts, health scores
3. **Market Metrics**: Cap rates, occupancy, rent metrics, demographics

---

## Metric ID Patterns

### Green Street Metrics
- Pattern: `GREEN_STREET_{METRIC_NAME}`
- Example: `GREEN_STREET_CAP_RATE`, `GREEN_STREET_HHI_3MI`

### Macro Rates Monthly
- Pattern: `MACRO_RATES_MONTHLY_{METRIC_NAME}`
- Example: `MACRO_RATES_MONTHLY_INTEREST_RATE`, `MACRO_RATES_MONTHLY_PERSONAL_INCOME`

---

## Files Created

1. `sql/validation/update_green_street_definitions_dynamic.sql` - Dynamic update script
2. `scripts/generate_green_street_definitions.py` - Python script to parse Data Dictionary
3. `docs/GREEN_STREET_DOCUMENTATION_UPDATE_SUMMARY.md` - This summary

---

## Documentation Quest Progress

### ✅ Completed
- **QCEW**: 3,150 metrics updated
- **Federal Reserve**: 824 metrics updated
- **Green Street**: 55+ metrics updated (MACRO_RATES_MONTHLY)

### ⏳ Remaining High-Priority
- Other Green Street datasets (if any)
- Additional vendors from documentation quest CSV

---

## Related Documentation

- **`DOCUMENTATION_QUEST_GUIDE.md`** - Complete guide
- **`DOCUMENTATION_QUEST_EXPORT_SUMMARY.md`** - Export summary
- **`QCEW_DOCUMENTATION_UPDATE_SUMMARY.md`** - QCEW documentation summary
- **`FEDERAL_RESERVE_DOCUMENTATION_UPDATE_SUMMARY.md`** - Federal Reserve documentation summary
- **`GOVERNANCE_REGISTRATION_FINAL_SUMMARY.md`** - Registration summary

---

**Last Updated**: 2026-01-31  
**Status**: ✅ Green Street Documentation Complete

