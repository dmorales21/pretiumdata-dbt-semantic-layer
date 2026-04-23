# Progress Household Structure Formulas - Implementation Details

**Date**: 2026-01-27  
**Status**: ✅ **IMPLEMENTED**  
**Purpose**: Document exact formulas for Progress cohort modifiers to enable edge case review

---

## 1. RENTER_MAINSTREAM_SHARE (for PROG_SFR_TRAD)

**Formula**:
```sql
CASE 
    WHEN (RENTER_HH_SIZE_1 + RENTER_HH_SIZE_2 + RENTER_HH_SIZE_3 + RENTER_HH_SIZE_4 + 
          RENTER_HH_SIZE_5 + RENTER_HH_SIZE_6 + RENTER_HH_SIZE_7PLUS) > 0
    THEN (RENTER_HH_SIZE_2 + RENTER_HH_SIZE_3 + 0.5 * RENTER_HH_SIZE_4) / 
         NULLIF(RENTER_HH_SIZE_1 + RENTER_HH_SIZE_2 + RENTER_HH_SIZE_3 + RENTER_HH_SIZE_4 + 
                RENTER_HH_SIZE_5 + RENTER_HH_SIZE_6 + RENTER_HH_SIZE_7PLUS, 0)
    ELSE 0.0
END
```

**Benchmark**: None (raw share)  
**Clamp**: [0, 1] via CASE logic  
**Edge Cases**:
- ✅ Handles zero renters (returns 0.0)
- ✅ Handles NULL via COALESCE in source columns
- ⚠️ Size 4 households get 0.5 weight (intentional: reserve full weight for FY)

**Default if Missing**: 0.5 (in DemandMass calculation)

---

## 2. RENTER_HOUSELIKE_SHARE (for PROG_SFR_AH)

**Formula**:
```sql
CASE 
    WHEN (RENTER_HH_SIZE_1 + RENTER_HH_SIZE_2 + RENTER_HH_SIZE_3 + RENTER_HH_SIZE_4 + 
          RENTER_HH_SIZE_5 + RENTER_HH_SIZE_6 + RENTER_HH_SIZE_7PLUS) > 0
    THEN (RENTER_HH_SIZE_2 + RENTER_HH_SIZE_3 + RENTER_HH_SIZE_4 + RENTER_HH_SIZE_5 + 
          RENTER_HH_SIZE_6 + RENTER_HH_SIZE_7PLUS) / 
         NULLIF(RENTER_HH_SIZE_1 + RENTER_HH_SIZE_2 + RENTER_HH_SIZE_3 + RENTER_HH_SIZE_4 + 
                RENTER_HH_SIZE_5 + RENTER_HH_SIZE_6 + RENTER_HH_SIZE_7PLUS, 0)
    ELSE 0.0
END
```

**Benchmark**: None (raw share)  
**Clamp**: [0, 1] via CASE logic  
**Edge Cases**:
- ✅ Handles zero renters (returns 0.0)
- ✅ Handles NULL via COALESCE in source columns
- ✅ All size 2+ households included (no weighting)

**Default if Missing**: 0.5 (in DemandMass calculation)

---

## 3. RENTER_FAMILY_SIZE_SHARE (for PROG_SFR_FY)

**Formula**:
```sql
CASE 
    WHEN (RENTER_HH_SIZE_1 + RENTER_HH_SIZE_2 + RENTER_HH_SIZE_3 + RENTER_HH_SIZE_4 + 
          RENTER_HH_SIZE_5 + RENTER_HH_SIZE_6 + RENTER_HH_SIZE_7PLUS) > 0
    THEN (RENTER_HH_SIZE_3 + RENTER_HH_SIZE_4 + RENTER_HH_SIZE_5 + RENTER_HH_SIZE_6 + 
          RENTER_HH_SIZE_7PLUS) / 
         NULLIF(RENTER_HH_SIZE_1 + RENTER_HH_SIZE_2 + RENTER_HH_SIZE_3 + RENTER_HH_SIZE_4 + 
                RENTER_HH_SIZE_5 + RENTER_HH_SIZE_6 + RENTER_HH_SIZE_7PLUS, 0)
    ELSE 0.0
END
```

**Benchmark**: None (raw share)  
**Clamp**: [0, 1] via CASE logic  
**Edge Cases**:
- ✅ Handles zero renters (returns 0.0)
- ✅ Handles NULL via COALESCE in source columns
- ✅ Only size 3+ households (family-oriented)

**Default if Missing**: 0.3 (in DemandMass calculation)

---

## 4. HH_WITH_CHILDREN_SHARE (intermediate for CHILDREN_MODIFIER)

**Formula**:
```sql
CASE 
    WHEN HH_TOTAL_B11005 > 0
    THEN HH_WITH_CHILDREN_UNDER18 / NULLIF(HH_TOTAL_B11005, 0)
    ELSE 0.0
END
```

**Benchmark**: None (raw share)  
**Clamp**: [0, 1] via CASE logic  
**Edge Cases**:
- ✅ Handles zero total households (returns 0.0)
- ⚠️ **NOT tenure-split**: This is tract-level, not renter-only
- ⚠️ **Risk 2**: Owner-heavy tracts can have high children share but low renter share

---

## 5. CHILDREN_MODIFIER (for PROG_SFR_FY)

**Formula**:
```sql
CASE 
    WHEN HH_TOTAL_B11005 > 0
    THEN GREATEST(0.0, LEAST(1.0, 
        (HH_WITH_CHILDREN_UNDER18 / NULLIF(HH_TOTAL_B11005, 0)) / 0.30
    )) * 
    -- Risk mitigation: multiply by sqrt(renter share) to prevent owner-heavy bias
    SQRT(GREATEST(0.0, LEAST(1.0, 
        RENTER_OCCUPIED / NULLIF(TOTAL_HOUSING_UNITS, 0)
    )))
    ELSE 0.0
END
```

**Benchmark**: 0.30 (30% of households have children)  
**Clamp**: [0, 1] via GREATEST/LEAST  
**Risk Mitigation**: Multiplied by `sqrt(RENTER_SHARE_PCT)` to prevent owner-heavy tracts from getting unearned boost

**Edge Cases**:
- ✅ Handles zero total households (returns 0.0)
- ✅ Handles zero renters (sqrt(0) = 0, so modifier = 0)
- ✅ Handles NULL via COALESCE in source columns
- ⚠️ **B11005 mismatch**: If B11005 total ≠ B25003 total, ratio can be > 1.0 (but clamped)
- ⚠️ **sqrt() behavior**: In owner-heavy tracts (renter share = 0.1), sqrt(0.1) = 0.316, so modifier is scaled down appropriately

**Default if Missing**: 1.0 (in DemandMass calculation, but should rarely be missing if B11005 loaded)

**Mathematical Behavior**:
- If children share = 0.30 and renter share = 1.0: modifier = 1.0 × 1.0 = 1.0
- If children share = 0.30 and renter share = 0.25: modifier = 1.0 × 0.5 = 0.5
- If children share = 0.15 and renter share = 1.0: modifier = 0.5 × 1.0 = 0.5
- If children share = 0.15 and renter share = 0.25: modifier = 0.5 × 0.5 = 0.25

---

## 6. MOVE_RATE_1YR (intermediate for STABILITY_MODIFIER)

**Formula**:
```sql
CASE 
    WHEN POPULATION_1_YEAR_AGO > 0
    THEN (MOVED_SAME_COUNTY + MOVED_SAME_STATE + MOVED_DIFFERENT_STATE) / 
         NULLIF(POPULATION_1_YEAR_AGO, 0)
    ELSE NULL
END
```

**Benchmark**: None (raw rate)  
**Clamp**: None (can exceed 1.0 if data quality issues)  
**Edge Cases**:
- ✅ Handles zero population (returns NULL)
- ⚠️ **Data quality**: If moved counts > population, rate > 1.0 (should be caught in validation)
- ⚠️ **B07401 availability**: May be NULL if table not loaded

---

## 7. STABILITY_MODIFIER (for PROG_SFR_FY)

**Formula**:
```sql
CASE 
    WHEN POPULATION_1_YEAR_AGO > 0
    THEN 1.0 - GREATEST(0.0, LEAST(1.0, MOVE_RATE_1YR / 0.25))
    ELSE 0.85  -- Risk mitigation: Default to 0.85 instead of 1.0 if B07401 not available
END
```

**Benchmark**: 0.25 (25% annual move rate = stress threshold)  
**Clamp**: [0, 1] via GREATEST/LEAST  
**Risk Mitigation**: Defaults to 0.85 (slightly penalizing) instead of 1.0 if B07401 not available

**Edge Cases**:
- ✅ Handles zero population (returns 0.85 default)
- ✅ Handles NULL MOVE_RATE_1YR (returns 0.85 default)
- ⚠️ **Extreme mobility**: If MOVE_RATE_1YR = 0.50, then modifier = 1.0 - 2.0 = -1.0, but clamped to 0.0
- ⚠️ **Extreme stability**: If MOVE_RATE_1YR = 0.05, then modifier = 1.0 - 0.2 = 0.8 (good)
- ⚠️ **B07401 availability**: If table not loaded, all tracts get 0.85 (intentional risk mitigation)

**Mathematical Behavior**:
- If move rate = 0.25 (benchmark): modifier = 1.0 - 1.0 = 0.0 (stress threshold)
- If move rate = 0.10 (stable): modifier = 1.0 - 0.4 = 0.6 (good)
- If move rate = 0.05 (very stable): modifier = 1.0 - 0.2 = 0.8 (excellent)
- If move rate = 0.50 (high churn): modifier = 1.0 - 2.0 = -1.0 → clamped to 0.0 (penalized)

**Default if Missing**: 0.85 (in both view and DemandMass calculation)

---

## 8. HAS_MOBILITY_DATA (boolean flag)

**Formula**:
```sql
CASE 
    WHEN POPULATION_1_YEAR_AGO > 0
    THEN TRUE
    ELSE FALSE
END
```

**Purpose**: Track data availability for reporting FY results split by flag  
**Edge Cases**:
- ✅ Handles NULL (returns FALSE)
- ✅ Handles zero population (returns FALSE)

---

## 9. PROG_SFR_TRAD_DEMAND_MASS

**Formula**:
```sql
BASE_SFR_RENTER_HOUSEHOLDS *
    COALESCE(RENTER_MAINSTREAM_SHARE, 0.5) *
    FN_AFFORDABILITY_WEIGHT(median_rent, avg_weekly_wage, 0.30) *
    COALESCE(PCT_COMMUTE_UNDER_30_MIN, 0.5)
```

**Edge Cases**:
- ✅ All modifiers have defaults
- ✅ BASE_SFR_RENTER_HOUSEHOLDS can be 0 (returns 0)
- ⚠️ **Ceiling check**: Must be ≤ RENTER_HOUSEHOLDS (validated separately)

---

## 10. PROG_SFR_AH_DEMAND_MASS

**Formula**:
```sql
BASE_SFR_RENTER_HOUSEHOLDS *
    COALESCE(RENTER_HOUSELIKE_SHARE, 0.5) *
    CASE 
        WHEN RENT_BURDEN_50PLUS > 0 AND RENTER_HOUSEHOLDS > 0
        THEN GREATEST(0.0, LEAST(1.0, (RENT_BURDEN_50PLUS / NULLIF(RENTER_HOUSEHOLDS, 0)) * 2.0))
        ELSE 0.0
    END *
    CASE 
        WHEN MEDIAN_RENT_CURRENT <= P75_RENT_CBSA
        THEN 1.0
        ELSE 0.5
    END
```

**Edge Cases**:
- ✅ All modifiers have defaults
- ✅ Handles zero rent burden (returns 0.0 for burden component)
- ⚠️ **Ceiling check**: Must be ≤ RENTER_HOUSEHOLDS (validated separately)

---

## 11. PROG_SFR_FY_DEMAND_MASS

**Formula**:
```sql
BASE_SFR_RENTER_HOUSEHOLDS *
    COALESCE(RENTER_FAMILY_SIZE_SHARE, 0.3) *
    COALESCE(CHILDREN_MODIFIER, 1.0) *
    FN_AFFORDABILITY_WEIGHT(median_rent, avg_weekly_wage, 0.30) *
    COALESCE(PCT_COMMUTE_UNDER_30_MIN, 0.5) *
    COALESCE(STABILITY_MODIFIER, 0.85)
```

**Edge Cases**:
- ✅ All modifiers have defaults
- ✅ BASE_SFR_RENTER_HOUSEHOLDS can be 0 (returns 0)
- ⚠️ **Ceiling check**: Must be ≤ RENTER_HOUSEHOLDS (validated separately)
- ⚠️ **Multiple modifiers**: Product of 5 modifiers can compound (validated separately)

---

## Known Edge Cases and Fixes

### Edge Case 1: B11005 Total ≠ B25003 Total
**Issue**: If B11005 total households ≠ B25003 total households, HH_WITH_CHILDREN_SHARE can be > 1.0  
**Fix**: Already clamped via GREATEST/LEAST in CHILDREN_MODIFIER  
**Status**: ✅ Handled

### Edge Case 2: Zero Renter Households
**Issue**: All renter share modifiers return 0.0, which is correct  
**Fix**: Already handled via CASE WHEN > 0  
**Status**: ✅ Handled

### Edge Case 3: Extreme Mobility (MOVE_RATE_1YR > 0.25)
**Issue**: STABILITY_MODIFIER can go negative  
**Fix**: Already clamped to [0, 1] via GREATEST/LEAST  
**Status**: ✅ Handled

### Edge Case 4: Owner-Heavy Tracts with High Children Share
**Issue**: CHILDREN_MODIFIER could be high even if few renters have children  
**Fix**: Multiplied by sqrt(RENTER_SHARE_PCT)  
**Status**: ✅ Handled (Risk 2 mitigation)

### Edge Case 5: Missing B07401 Data
**Issue**: STABILITY_MODIFIER defaults to 1.0, making FY "pretend-sticky" everywhere  
**Fix**: Default changed to 0.85, plus HAS_MOBILITY_DATA flag added  
**Status**: ✅ Handled (Risk 1 mitigation)

---

## Validation Queries

See `sql/analytics/modeled/validate_progress_household_structure_cohorts.sql` for comprehensive validation checks.

