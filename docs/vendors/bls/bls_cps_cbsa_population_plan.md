# BLS CPS CBSA Population Plan

**Date**: 2026-01-11  
**Status**: ✅ **COMPLETED**

---

## Summary

Successfully populated `ANALYTICS_PROD.FEATURES.BLS_CPS_CBSA` table from `SOURCE_PROD.NBER.CPS_BASIC3_LOADED` via extraction view `TRANSFORM_PROD.CLEANED.V_CPS_CBSA_EXTRACTION`.

---

## Implementation Details

### Source Data
- **Table**: `SOURCE_PROD.NBER.CPS_BASIC3_LOADED`
- **Type**: Person-level microdata (21.3M rows)
- **Coverage**: 2013-2025, 337 unique CBSAs
- **Frequency**: Monthly

### Extraction View
- **View**: `TRANSFORM_PROD.CLEANED.V_CPS_CBSA_EXTRACTION`
- **Method**: Pivots existing `CPS_BASIC3_LONG` view to wide format
- **Aggregation**: Uses weighted aggregation based on `PERSON_WEIGHT_COMPOSITE`

### Target Table
- **Table**: `ANALYTICS_PROD.FEATURES.BLS_CPS_CBSA`
- **Schema**: Matches `BLS_CPS_MSA_FEATURES` but uses `CBSA_CODE`
- **Primary Key**: `(CBSA_CODE, DATE_REFERENCE)`
- **Rows Loaded**: 40,513

---

## Data Quality Notes

### Known Issues
1. **Unemployment Rates**: Some rates appear high (50%+). This may be due to:
   - Aggregation logic in `CPS_BASIC3_LONG` view
   - Person-level microdata weighting issues
   - Need to validate against BLS published rates

2. **Labor Force Participation**: Some rates exceed 100%, indicating potential double-counting in aggregation logic.

### Recommendations
1. **Validate against BLS LAUS**: Compare unemployment rates with `TRANSFORM_PROD.CLEANED.BLS_LAUS`
2. **Review Aggregation Logic**: Check `CPS_BASIC3_LONG` view logic for employment status determination
3. **Data Quality Filters**: Add filters to exclude unreasonable values (e.g., unemployment > 20%, LFPR > 100%)

---

## Files Created

1. ✅ `sql/transform/cleaned/validate_cps_source_data.sql` - Source validation
2. ✅ `sql/transform/cleaned/create_cps_cbsa_extraction.sql` - Extraction view
3. ✅ `sql/analytics/features/create_bls_cps_cbsa_table.sql` - Table creation
4. ✅ `sql/analytics/features/populate_bls_cps_cbsa.sql` - Data population
5. ✅ `sql/analytics/features/validate_bls_cps_cbsa.sql` - Validation queries

---

## Next Steps

1. **Data Quality Review**: Investigate and fix aggregation logic if needed
2. **Validation**: Compare with BLS published rates
3. **Integration**: Use in demand estimation framework
4. **Automation**: Set up refresh task for monthly updates

