# Signal Tenancy Code Addition Progress
**Date**: 2026-01-31  
**Status**: ⏳ **IN PROGRESS** - 14/51 Complete (27%)  
**Purpose**: Track tenancy_code addition to all signal models

---

## Progress Summary

**Total Signals**: 51+  
**With Tenancy Code**: 14 (27%)  
**Missing Tenancy Code**: 37 (73%)

---

## Completed Signals (14)

### `models/analytics/scores/` (8 complete)
1. ✅ `fct_velocity_signal.sql` - `OWNERSHIP`
2. ✅ `fct_absorption_signal.sql` - `RENTAL`
3. ✅ `fct_place_safety_signal.sql` - `MIXED`
4. ✅ `fct_place_education_signal.sql` - `MIXED`
5. ✅ `fct_place_amenities_signal.sql` - `MIXED`
6. ✅ `fct_rent_burden_signal.sql` - `RENTAL`
7. ✅ `fct_price_momentum_signal.sql` - `OWNERSHIP`
8. ✅ `fct_supply_pressure_signal.sql` - `MIXED`
9. ✅ `fct_rent_hpa_divergence_signal.sql` - `MIXED`
10. ✅ `fct_absorption_signal_cbsa.sql` - `RENTAL`
11. ✅ `fct_absorption_level_signal.sql` - `RENTAL`
12. ✅ `fct_climate_risk_signal.sql` - `MIXED`
13. ✅ `fct_permit_activity_signal.sql` - `MIXED`
14. ✅ `fct_gc_capacity_signal.sql` - `MIXED`

### `models/analytics_prod/scores/` (Already have tenancy_code via macro)
- ✅ `fct_absorption_signal_mls_enhanced.sql` - Uses `infer_tenancy_code()` macro
- ✅ `fct_concessions_signal.sql` - Uses `infer_tenancy_code()` macro
- ✅ `fct_multifamily_health_signal.sql` - Uses `infer_tenancy_code()` macro
- ✅ `fct_btr_market_signal.sql` - Uses `infer_tenancy_code()` macro
- ✅ `fct_liquidity_signal.sql` - Uses `infer_tenancy_code()` macro
- ✅ `fct_velocity_signal_mls_enhanced.sql` - Uses `infer_tenancy_code()` macro
- ✅ `fct_affordable_housing_signal.sql` - Uses `infer_tenancy_code()` macro
- ✅ `fct_listing_quality_signal.sql` - Uses `infer_tenancy_code()` macro
- ✅ `fct_tenancy_tradeoff_signal.sql` - Uses `infer_tenancy_code()` macro
- ✅ `fct_valuation_signal.sql` - Uses `infer_tenancy_code()` macro
- ✅ `fct_market_competitiveness_signal.sql` - Uses `infer_tenancy_code()` macro
- ✅ `fct_mls_velocity_signal.sql` - Uses `infer_tenancy_code()` macro
- ✅ `fct_supply_pressure_signal_mls_enhanced.sql` - Uses `infer_tenancy_code()` macro

**Note**: Many signals in `analytics_prod/scores/` already use the `infer_tenancy_code()` macro, so they're already covered!

---

## Remaining Signals (37)

### `models/analytics_prod/scores/` (Need to check/add)
- ⏳ `fct_absorption_intensity_signal.sql`
- ⏳ `fct_absorption_momentum_signal.sql`
- ⏳ `fct_economic_momentum_signal.sql`
- ⏳ `fct_lineage_signal.sql`
- ⏳ `fct_ownership_party_competition_signal.sql`
- ⏳ `fct_ownership_party_concentration_signal.sql`
- ⏳ `fct_parcllabs_ownership_signal.sql`
- ⏳ `fct_population_growth_signal.sql`

### `models/analytics/scores/bkfs/` (3 signals)
- ⏳ `fct_delinquency_risk_signal.sql`
- ⏳ `fct_distressed_opportunity_signal.sql`
- ⏳ `fct_loan_performance_signal.sql`

### `models/analytics/scores/opco/` (2 signals)
- ⏳ `signal_absorption_mf_equity.sql`
- ⏳ `signal_absorption_sfr_equity.sql`

### `models/analytics/features/carto_amenitization/signals/` (5 signals)
- ⏳ `signal_btr_amenitization.sql`
- ⏳ `signal_mf_core_amenitization.sql`
- ⏳ `signal_mf_premium_amenitization.sql`
- ⏳ `signal_sf_amenitization.sql`
- ⏳ `signal_valueadd_amenitization.sql`

### `models/analytics/features/mf_intelligence/signals/` (6 signals)
- ⏳ `signal_mf_absorption_velocity.sql`
- ⏳ `signal_mf_class_stress.sql`
- ⏳ `signal_mf_composite.sql`
- ⏳ `signal_mf_pricing_momentum.sql`
- ⏳ `signal_mf_quality_momentum.sql`
- ⏳ `signal_mf_supply_pressure.sql`

---

## Tenancy Code Mapping Strategy

### RENTAL (Lease-up, rent metrics)
- Absorption signals
- Rent burden signal
- Concessions signal
- Multifamily health signal
- Affordable housing signal
- BTR market signal
- OpCo absorption signals

### OWNERSHIP (Sales, price metrics)
- Velocity signals
- Price momentum signal
- Market competitiveness signal
- Listing quality signal
- Valuation signal
- Ownership party signals
- ParclLabs ownership signal

### MIXED (Universal metrics)
- Safety signal
- Education signal
- Amenities signal
- Climate risk signal
- Supply pressure signal
- Economic momentum signal
- Population growth signal
- Permit activity signal
- GC capacity signal
- Rent-HPA divergence signal

### CAPITAL (BKFS - loan metrics)
- Delinquency risk signal
- Distressed opportunity signal
- Loan performance signal

---

## Next Steps

1. **Continue adding tenancy_code** to remaining 37 signals
2. **Identify signal creation opportunities** from existing metrics
3. **Document all signals** in schema.yml
4. **Create signal opportunity analysis** for new signal development

---

**Last Updated**: 2026-01-31  
**Status**: ⏳ 14/51 Complete (27%) - Continuing with remaining signals

