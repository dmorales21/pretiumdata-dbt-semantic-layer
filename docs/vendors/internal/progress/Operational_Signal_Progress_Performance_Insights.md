# Operational Signal: Progress Performance Insights

**Date**: 2026-01-27  
**Purpose**: Understanding Progress Residential operational performance through signal metrics

---

## 📊 Overview

The operational signal system tracks Progress Residential performance across multiple dimensions:
- **Velocity**: Market speed and transaction velocity
- **Occupancy**: Physical and economic occupancy rates
- **Pricing Power**: Renewal and new lease premiums
- **Returns**: Opex ratio, NOI margin, cash yield
- **Quality**: Property tier distribution and portfolio quality score

---

## 🎯 Key Operational Metrics

### 1. Velocity Metrics

**Source**: `FEATURE_PORTFOLIO_OPERATIONS_CBSA`

**Metrics**:
- `days_to_lease_new`: Days from acquisition to lease
- `days_to_lease_turned`: Days from move-out to move-in
- `lease_up_velocity_score`: Percentile rank of lease-up speed (0-100)
- `portfolio_velocity_factor`: Weighted velocity score (60% market DOM + 40% lease-up)

**Progress Performance**:
- **Data Source**: `PROGRESS_PROPERTIES` (occupancy_status)
- **Coverage**: All Progress markets with property data
- **Status**: ⚠️ **PARTIAL** - Limited to occupancy status, lacks full lease-up data

**Insights**:
- Progress velocity is calculated from occupancy status only
- Missing: Actual days-to-lease data (requires lease event data)
- Market DOM component uses Realtor.com/Redfin data (may be stale)

---

### 2. Occupancy Quality

**Metrics**:
- `physical_occupancy`: Occupied units / total units
- `economic_occupancy`: Rent collected / (units × market rent)
- `vacancy_loss`: Physical - economic occupancy
- `concession_burden`: Concession impact

**Progress Performance**:
- **Physical Occupancy**: ✅ Available from `occupancy_status`
- **Economic Occupancy**: ❌ Not available (requires ITD rent collected data)
- **Coverage**: All Progress markets with property data

**Insights**:
- Progress has physical occupancy but lacks economic occupancy
- Economic occupancy requires ITD (inception-to-date) rent collection data
- Compare to Imagine Homes which has full ITD metrics

---

### 3. Pricing Power

**Metrics**:
- `renewal_premium_pct`: Renewal rent premium vs prior rent
- `new_lease_premium_pct`: New lease premium vs market rent
- `pricing_power`: Composite pricing score (0.70 × renewal + 0.30 × new lease)

**Progress Performance**:
- **Status**: ⏳ **PLACEHOLDER** - Requires historical rent data
- **Data Needed**: 
  - Historical rent at renewal
  - Market rent comparison
  - New lease rent vs market rent

**Insights**:
- Pricing power metrics are not yet populated for Progress
- Requires integration of rent history and market rent data
- Can be calculated from `PROGRESS_PROPERTIES.RENT_CURRENT` if historical data available

---

### 4. Returns Metrics

**Metrics**:
- `opex_ratio`: Operating expense ratio (expenses / rent collected)
- `noi_margin`: NOI margin ((rent - expenses) / rent)
- `cash_yield_pct`: Cash yield (gross yield × NOI margin)

**Progress Performance**:
- **Status**: ❌ **NOT AVAILABLE** - Requires expense data
- **Data Needed**: 
  - ITD expenses
  - ITD rent collected
  - Property-level expense allocation

**Insights**:
- Progress lacks ITD operational metrics (rent collected, expenses, net income)
- Only `PURCHASE_PRICE` and `RENT_CURRENT` available
- Compare to Imagine Homes which has full ITD metrics

---

### 5. Quality Tiers

**Metrics**:
- `pct_a_tier`: % A-tier properties (high yield, high occupancy)
- `pct_b_tier`: % B-tier properties (moderate yield, good occupancy)
- `pct_c_tier`: % C-tier properties (lower yield, lower occupancy)
- `portfolio_quality_score`: Composite quality score

**Progress Performance**:
- **Calculation**: Based on aggregate yield and occupancy
  - A-tier: Yield > 8% AND occupancy > 95%
  - B-tier: Yield > 7% AND occupancy > 90%
- **Coverage**: All Progress markets with property data

**Insights**:
- Quality tiers are calculated from aggregate metrics
- Uses `RENT_CURRENT` and `PURCHASE_PRICE` for yield calculation
- Confidence adjustment based on sample size (property count)

---

## 📈 Operational Signal Dashboard Queries

### Progress Performance by Market

```sql
SELECT 
    op.ID_CBSA,
    map.NAME_CBSA,
    op.OPCO,
    op.property_count,
    op.physical_occupancy,
    op.economic_occupancy,
    op.vacancy_loss,
    op.days_to_lease_turned,
    op.lease_up_velocity_score,
    op.portfolio_velocity_factor,
    op.pct_a_tier,
    op.pct_b_tier,
    op.portfolio_quality_score,
    op.confidence_adj,
    op.data_quality_flag
FROM ANALYTICS_PROD.FEATURES.FEATURE_PORTFOLIO_OPERATIONS_CBSA op
JOIN TRANSFORM_PROD.REF.MAP_CBSA map
    ON op.ID_CBSA = map.ID_CBSA
WHERE op.OPCO = 'PROGRESS_RESIDENTIAL'
  AND op.DATE_REFERENCE >= DATEADD(MONTH, -3, CURRENT_DATE())
ORDER BY op.portfolio_quality_score DESC, op.property_count DESC;
```

### Progress vs Market Velocity

```sql
SELECT 
    op.ID_CBSA,
    map.NAME_CBSA,
    op.portfolio_velocity_factor AS PROGRESS_VELOCITY,
    vel.VELOCITY_SCORE AS MARKET_VELOCITY,
    vel.VELOCITY_SCORE - op.portfolio_velocity_factor AS VELOCITY_DIFF,
    CASE 
        WHEN op.portfolio_velocity_factor > vel.VELOCITY_SCORE THEN 'OUTPERFORMING'
        WHEN op.portfolio_velocity_factor < vel.VELOCITY_SCORE THEN 'UNDERPERFORMING'
        ELSE 'IN LINE'
    END AS PERFORMANCE
FROM ANALYTICS_PROD.FEATURES.FEATURE_PORTFOLIO_OPERATIONS_CBSA op
JOIN TRANSFORM_PROD.REF.MAP_CBSA map
    ON op.ID_CBSA = map.ID_CBSA
LEFT JOIN ANALYTICS_PROD.MODELED.FACT_VELOCITY_SIGNAL_CBSA vel
    ON op.ID_CBSA = vel.ID_CBSA
    AND vel.DATE_REFERENCE >= DATEADD(MONTH, -3, CURRENT_DATE())
WHERE op.OPCO = 'PROGRESS_RESIDENTIAL'
  AND op.DATE_REFERENCE >= DATEADD(MONTH, -3, CURRENT_DATE())
ORDER BY VELOCITY_DIFF DESC;
```

### Progress Occupancy vs Market

```sql
SELECT 
    op.ID_CBSA,
    map.NAME_CBSA,
    op.physical_occupancy AS PROGRESS_OCCUPANCY,
    op.vacancy_loss AS PROGRESS_VACANCY_LOSS,
    CASE 
        WHEN op.physical_occupancy >= 0.95 THEN 'EXCELLENT'
        WHEN op.physical_occupancy >= 0.90 THEN 'GOOD'
        WHEN op.physical_occupancy >= 0.85 THEN 'FAIR'
        ELSE 'POOR'
    END AS OCCUPANCY_TIER
FROM ANALYTICS_PROD.FEATURES.FEATURE_PORTFOLIO_OPERATIONS_CBSA op
JOIN TRANSFORM_PROD.REF.MAP_CBSA map
    ON op.ID_CBSA = map.ID_CBSA
WHERE op.OPCO = 'PROGRESS_RESIDENTIAL'
  AND op.DATE_REFERENCE >= DATEADD(MONTH, -3, CURRENT_DATE())
ORDER BY op.physical_occupancy DESC;
```

---

## ⚠️ Data Gaps and Limitations

### 1. Missing ITD Metrics
**Impact**: Cannot calculate true economic occupancy, opex ratio, NOI margin

**Solution**: 
- Integrate ITD rent collection data
- Integrate expense data (operating expenses, maintenance, etc.)
- Calculate economic occupancy: `rent_collected / (units × market_rent)`

### 2. Missing Lease Event Data
**Impact**: Cannot calculate actual days-to-lease metrics

**Solution**:
- Integrate lease event data (move-in dates, lease start dates)
- Calculate `days_to_lease_new` from acquisition to lease start
- Calculate `days_to_lease_turned` from move-out to move-in

### 3. Missing Historical Rent Data
**Impact**: Cannot calculate pricing power metrics

**Solution**:
- Integrate rent history (renewal rent, prior rent, new lease rent)
- Compare to market rent (ZORI, MLS rental data)
- Calculate renewal and new lease premiums

### 4. Stale Market Data
**Impact**: Market DOM component of velocity may be outdated

**Solution**:
- Ensure Realtor.com/Redfin data is current (within 30 days)
- Use most recent data per market (not just latest date)
- See `verify_data_freshness.sql` for data freshness checks

---

## 🎯 Recommendations

### Immediate Actions
1. **Verify Data Freshness**: Run `verify_data_freshness.sql` to ensure Realtor/Redfin data is current
2. **Check Progress Coverage**: Verify all Progress markets have operational metrics
3. **Compare to Imagine**: Use Imagine Homes as benchmark (has full ITD metrics)

### Short-Term Enhancements
1. **Integrate ITD Data**: Add rent collection and expense data for economic occupancy
2. **Add Lease Events**: Integrate lease event data for velocity calculations
3. **Add Rent History**: Integrate historical rent data for pricing power

### Long-Term Improvements
1. **Real-Time Updates**: Automate operational metrics updates
2. **Benchmarking**: Compare Progress to market averages and Imagine Homes
3. **Predictive Metrics**: Use operational metrics to predict future performance

---

## 📊 Key Performance Indicators (KPIs)

### Portfolio-Level KPIs
- **Average Physical Occupancy**: Target > 95%
- **Average Economic Occupancy**: Target > 93%
- **Average Days to Lease**: Target < 30 days
- **Portfolio Quality Score**: Target > 0.80

### Market-Level KPIs
- **Velocity vs Market**: Progress should outperform market velocity
- **Occupancy vs Market**: Progress should maintain higher occupancy
- **Quality Distribution**: Target > 60% A/B tier properties

---

**Document Version**: 1.0  
**Last Updated**: 2026-01-27

