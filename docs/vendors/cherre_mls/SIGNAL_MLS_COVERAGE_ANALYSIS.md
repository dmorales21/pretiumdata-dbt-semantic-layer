# Signal Framework: MLS Data Coverage & Gap Analysis

**Date**: 2026-01-29  
**Purpose**: Comprehensive evaluation of MLS data integration into signal framework  
**Status**: 🔍 **ANALYSIS IN PROGRESS**

---

## Executive Summary

### MLS Data Assets Discovered

**Massive MLS Coverage**:
- **HOUSING_HOU_PRICING_CHERRE_MLS**: 1.93B rows, 18.5GB
- **HOUSING_HOU_INVENTORY_CHERRE_MLS**: 518M rows, 5.5GB  
- **FACT_HOUSING_PRICING_CHERRE_MLS**: 613M rows, 9.4GB (legacy)

### Current Signal Status (CRITICAL FINDING)

**Only 1 of 11 signals has data**:
- ✅ **OWNERSHIP**: 336 CBSAs with data
- ❌ **VELOCITY**: 0 CBSAs
- ❌ **ABSORPTION**: 0 CBSAs  
- ❌ **SUPPLY_PRESSURE**: 0 CBSAs
- ❌ **PRICE_MOMENTUM**: 0 CBSAs
- ❌ **MLS_VELOCITY**: 0 CBSAs (despite 518M rows of MLS data!)

**This is a critical disconnect** - we have rich MLS data but signals aren't populated.

---

## MLS Data Coverage Analysis

### Available MLS Metrics

#### Pricing Metrics (from HOUSING_HOU_PRICING_CHERRE_MLS)
*Coverage data loading...*

#### Inventory Metrics (from HOUSING_HOU_INVENTORY_CHERRE_MLS)  
*Coverage data loading...*

---

## Signal Framework Review

### Existing Signals

| Signal | Category | Input Taxons | Current Coverage | MLS Opportunity |
|-------|----------|--------------|------------------|-----------------|
| **VELOCITY** | LIQUIDITY | HOU_DEMAND, HOU_INVENTORY | 0 CBSAs ❌ | HIGH - DOM, active listings, pending |
| **ABSORPTION** | DEMAND | HOU_DEMAND, HOU_INVENTORY | 0 CBSAs ❌ | HIGH - Sold/active ratio, turnover |
| **SUPPLY_PRESSURE** | SUPPLY | HOU_INVENTORY, HOU_STARTS | 0 CBSAs ❌ | HIGH - Active inventory, new listings |
| **PRICE_MOMENTUM** | SENTIMENT | HOU_PRICING | 0 CBSAs ❌ | HIGH - List price changes, PPSF trends |
| **MLS_VELOCITY** | LIQUIDITY | HOU_DEMAND | 0 CBSAs ❌ | CRITICAL - Built for MLS but not populated |
| **OWNERSHIP** | OWNERSHIP | HOU_OWNERSHIP | 336 CBSAs ✅ | LOW - Already has data |
| **RENT_BURDEN** | AFFORDABILITY | HH_AFFORDABILITY | ? | LOW - Rent-focused |

### Signal Gap Analysis

#### Critical Issue: Signal Models Exist But No Data

The signal *models* are built, but they're returning 0 rows. This suggests:

1. **Data Pipeline Issue**: MLS data exists but isn't flowing into signal calculations
2. **Join/Filter Issue**: Signal queries may be filtering out all data
3. **Schema Mismatch**: Column names or structures may not align
4. **Geography Mismatch**: CBSA codes may not be matching

---

## Recommended Actions

### Immediate Priorities (Next 2-4 hours)

1. **Diagnose MLS_VELOCITY Signal** (CRITICAL)
   - This signal is specifically built for MLS data
   - Has 518M rows of input data available
   - Currently returns 0 rows
   - **Action**: Review `fct_mls_velocity_signal.sql` to find the disconnect

2. **Check Data Pipeline Flow**
   - Verify MLS data → fact tables → signal input
   - Check for schema changes or column renames
   - Validate CBSA code formats

3. **Test Signal Calculations Manually**
   - Run simplified versions of signal queries
   - Identify where data is being filtered out
   - Fix joins, filters, or aggregations

### Short-Term Enhancements (1-2 days)

4. **Enhance Signals with MLS Backstop**
   - **VELOCITY**: Add MLS DOM, pending ratio as fallback
   - **ABSORPTION**: Use MLS sold/active ratio
   - **SUPPLY_PRESSURE**: Use MLS new listings, inventory levels
   - **PRICE_MOMENTUM**: Use MLS price changes, PPSF trends

5. **Create MLS-Specific Product Differentiation**
   - MLS data likely has SF vs MF differentiation
   - Enable product-specific signal scores
   - Leverage `product_type_code` in MLS tables

### Medium-Term Improvements (1 week)

6. **Build New MLS-Powered Signals**
   - **PRICE_COMPETITIVENESS**: List vs sold price ratio
   - **LISTING_QUALITY**: Price reductions, DOM trends
   - **MARKET_TIMING**: Seasonal patterns, optimal listing periods

7. **Create Coverage Reports**
   - Which CBSAs have MLS data vs signal coverage
   - Identify gaps where MLS can fill in
   - Monitor signal data quality over time

---

## Next Steps

1. **IMMEDIATE**: Check why `FCT_MLS_VELOCITY_SIGNAL` returns 0 rows
2. **IMMEDIATE**: Validate MLS data schema and column names in signal queries
3. **SHORT-TERM**: Run test queries to identify the disconnect
4. **SHORT-TERM**: Fix signal queries and rebuild

---

## Questions to Answer

- [ ] Why does `HOUSING_HOU_INVENTORY_CHERRE_MLS` have 518M rows but no CBSA coverage reported?
- [ ] Are CBSA codes stored differently in MLS tables vs signal expectations?
- [ ] Do MLS metrics have the expected `metric_id` values signal queries are looking for?
- [ ] Is there a date range mismatch causing all data to be filtered out?
- [ ] Are product type codes properly set in MLS data?

---

*Analysis continuing...*

