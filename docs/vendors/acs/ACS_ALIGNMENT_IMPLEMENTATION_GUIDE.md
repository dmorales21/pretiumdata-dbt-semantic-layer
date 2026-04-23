# ACS Alignment Implementation Guide

**Date**: 2026-01-08  
**Purpose**: Guide for systematically analyzing and fixing ACS data quality issues across all offering views

---

## Overview

This guide provides a systematic approach to identifying and resolving ACS data quality issues across all offering-specific views at both CBSA and ZIP levels.

---

## Phase 1: Discovery and Analysis

### Step 1.1: Run Diagnostic Scripts

Execute all diagnostic scripts to gather comprehensive information:

```bash
cd /Users/aposes/Documents/STRATA
./scripts/run_acs_alignment_analysis.sh
```

Or run individually:

1. **`scripts/analyze_acs_data_sources.py`**
   - Discovers all ACS tables across TRANSFORM_PROD schemas
   - Compares row counts, date ranges, geography coverage
   - Output: `exports/fund_7_q1_2026/metadata/acs_data_sources_analysis.json`

2. **`scripts/analyze_offering_view_acs_dependencies.py`**
   - Maps ACS column dependencies in offering views
   - Identifies source view/table references
   - Output: `exports/fund_7_q1_2026/metadata/offering_view_acs_dependencies.json`

3. **`scripts/analyze_acs_data_quality_gaps.py`**
   - Calculates NULL rates on ACS columns
   - Identifies views with >50% NULL rates
   - Output: `exports/fund_7_q1_2026/metadata/acs_data_quality_gaps.json`

4. **`scripts/discover_cleaned_acs_tables.py`**
   - Finds ACS tables in TRANSFORM_PROD.CLEANED
   - Compares structures with FACT tables
   - Output: `exports/fund_7_q1_2026/metadata/cleaned_acs_tables_discovery.json`

5. **`scripts/compare_acs_coverage.py`**
   - Compares coverage across ACS sources
   - Identifies best source by geography level
   - Output: `exports/fund_7_q1_2026/metadata/acs_coverage_comparison.json`

6. **`scripts/check_view_acs_alignment.py`**
   - Verifies view alignment and consistency
   - Checks for deprecated sources
   - Output: `exports/fund_7_q1_2026/metadata/view_acs_alignment_check.json`

### Step 1.2: Review Diagnostic Results

Review all JSON output files to identify:
- Which ACS tables exist in CLEANED schema
- Which views have missing ACS columns
- Which views have high NULL rates
- Which source has best coverage

---

## Phase 2: Identify Alignment Needs

### Step 2.1: Compare CLEANED vs FACT Tables

Based on `cleaned_acs_tables_discovery.json`:
- If CLEANED tables have better coverage → Update stratification views
- If CLEANED tables have additional columns → Consider adding to FACT tables
- If FACT tables are better → Keep current implementation

### Step 2.2: Identify Missing ACS Columns

Based on `acs_data_quality_gaps.json`:
- List all views with >50% NULL rate on critical columns
- Identify which columns are missing vs just NULL
- Determine if data exists in source but not joined

### Step 2.3: Check View Alignment

Based on `view_acs_alignment_check.json`:
- Verify all views use consistent ACS sources
- Identify views using deprecated sources
- Check ZIP vs CBSA alignment

---

## Phase 3: Systematic Resolution

### Step 3.1: Update Stratification Views

**If CLEANED tables have better data:**

1. Update `sql/analytics/markets/create_zip_stratification_view.sql`:
   - Change FROM clause to use CLEANED table
   - Update column mappings if needed
   - Ensure date filtering is correct

2. Update `sql/analytics/markets/create_cbsa_stratification_view.sql`:
   - Use CLEANED CBSA table if available
   - Or aggregate from updated ZIP view
   - Ensure consistency with ZIP view

**If FACT tables are better:**
- Keep current implementation
- Focus on populating FACT tables if they're missing data

### Step 3.2: Fix Missing ACS Columns

For each offering view group:

#### Anchor Loans (CBSA & ZIP)
- **File**: `sql/analytics/modeled/fix_anchor_loans_acs_alignment.sql`
- **Action**: Update buyer_cohorts CTE to populate NULL columns from tenant cohort views
- **Columns to fix**: `BUYER_AGE_COHORT`, `BUYER_EDUCATION_COHORT`
- **Source**: `V_TENANT_COHORT_STRATIFICATION_CBSA` / `V_TENANT_COHORT_STRATIFICATION_ZIP`

#### Progress SFR (ZIP)
- **File**: `sql/analytics/modeled/fix_progress_sfr_acs_alignment.sql`
- **Action**: Verify renter_cohorts CTE is properly populated
- **Columns to verify**: All `ZIP_RENTER_*` columns
- **Source**: `V_TENANT_COHORT_STRATIFICATION_ZIP`

#### Multifamily (CBSA & ZIP)
- **File**: `sql/analytics/modeled/fix_multifamily_acs_alignment.sql`
- **Action**: Add ACS structure and renter demographics if missing
- **Columns to add**: `PCT_5P_UNITS`, `PCT_RENTER`, `MEDIAN_RENT`
- **Source**: `V_CBSA_STRATIFICATION` / `V_PRODUCT_TYPE_ACS_STRATIFICATION_ZIP`

#### Deephaven/REM (ZIP)
- **File**: `sql/analytics/modeled/fix_deephaven_acs_alignment.sql`
- **Action**: Add buyer cohort data similar to Anchor Loans
- **Columns to add**: `ZIP_BUYER_INCOME_COHORT`, `ZIP_BUYER_HOUSEHOLD_TYPE_COHORT`
- **Source**: `V_TENANT_COHORT_STRATIFICATION_ZIP`

#### Selene/RES (ZIP)
- **File**: `sql/analytics/modeled/fix_selene_acs_alignment.sql`
- **Action**: Add renter cohort data similar to Progress SFR
- **Columns to add**: `ZIP_RENTER_INCOME_COHORT`, `ZIP_RENT_BURDEN_STRATIFICATION`
- **Source**: `V_TENANT_COHORT_STRATIFICATION_ZIP`

### Step 3.3: Align CBSA and ZIP Levels

1. **Ensure ZIP views inherit CBSA data when ZIP is NULL:**
   ```sql
   COALESCE(zip_acs.PCT_1_UNIT, cbsa_acs.PCT_1_UNIT) AS ZIP_PCT_1_UNIT
   ```

2. **Verify CBSA aggregation is correct:**
   - CBSA should aggregate ZIP data correctly
   - Check that CBSA totals match sum of ZIPs

3. **Add fallback logic in all views:**
   - Use CBSA data when ZIP data is missing
   - Use ZIP data when available (more granular)

### Step 3.4: Update Offering-Specific Filters

For each offering view, update filters to handle NULLs:

**Before:**
```sql
WHERE ZIP_RENTER_INCOME_COHORT = 'PROFESSIONAL_RENTER_COHORT'
```

**After:**
```sql
WHERE (ZIP_RENTER_INCOME_COHORT = 'PROFESSIONAL_RENTER_COHORT'
       OR (ZIP_RENTER_INCOME_COHORT IS NULL 
           AND (ZIP_RENTER_INCOME_STRATIFICATION = 'HIGH_INCOME'
                OR ZIP_PCT_HIGH_INCOME >= 0.30)))
```

This ensures markets aren't excluded due to missing cohort classifications.

---

## Phase 4: Validation

### Step 4.1: Run Validation Scripts

After applying fixes, run validation:

```bash
python3 scripts/validate_acs_data_quality.py
python3 scripts/validate_acs_alignment.py
python3 scripts/validate_offering_views.py
```

### Step 4.2: Check Success Criteria

Verify:
1. **Data Quality**: <20% NULL rate on critical ACS columns
2. **Coverage**: >80% of markets/ZIPs have complete ACS data
3. **Alignment**: All views use consistent ACS sources
4. **Consistency**: ZIP aggregates to CBSA correctly
5. **Completeness**: All offering views have tenant cohort data

### Step 4.3: Compare Before/After

Compare validation results:
- Before: NULL rates from `acs_data_quality_gaps.json`
- After: NULL rates from `acs_data_quality_validation.json`
- Target: <20% NULL rate improvement

---

## Implementation Checklist

- [ ] Run all diagnostic scripts
- [ ] Review diagnostic results
- [ ] Identify best ACS data source (CLEANED vs FACT)
- [ ] Update stratification views if needed
- [ ] Fix missing ACS columns in Anchor Loans views
- [ ] Fix missing ACS columns in Progress SFR views
- [ ] Fix missing ACS columns in Multifamily views
- [ ] Fix missing ACS columns in Deephaven views
- [ ] Fix missing ACS columns in Selene views
- [ ] Add CBSA fallback logic to ZIP views
- [ ] Update offering filters to handle NULLs
- [ ] Run validation scripts
- [ ] Verify success criteria met
- [ ] Document changes made

---

## Files Created

### Diagnostic Scripts
- `scripts/analyze_acs_data_sources.py`
- `scripts/analyze_offering_view_acs_dependencies.py`
- `scripts/analyze_acs_data_quality_gaps.py`
- `scripts/discover_cleaned_acs_tables.py`
- `scripts/compare_acs_coverage.py`
- `scripts/check_view_acs_alignment.py`

### Fix Scripts
- `sql/analytics/markets/fix_zip_stratification_acs_source.sql`
- `sql/analytics/markets/fix_cbsa_stratification_acs_source.sql`
- `sql/analytics/modeled/fix_anchor_loans_acs_alignment.sql`
- `sql/analytics/modeled/fix_progress_sfr_acs_alignment.sql`
- `sql/analytics/modeled/fix_multifamily_acs_alignment.sql`
- `sql/analytics/modeled/fix_deephaven_acs_alignment.sql`
- `sql/analytics/modeled/fix_selene_acs_alignment.sql`

### Validation Scripts
- `scripts/validate_acs_data_quality.py`
- `scripts/validate_acs_alignment.py`
- `scripts/validate_offering_views.py`

### Master Script
- `scripts/run_acs_alignment_analysis.sh`

---

## Next Steps

1. **Run diagnostics**: Execute `./scripts/run_acs_alignment_analysis.sh`
2. **Review results**: Check JSON files in `exports/fund_7_q1_2026/metadata/`
3. **Apply fixes**: Update SQL files based on diagnostic findings
4. **Validate**: Run validation scripts to verify improvements
5. **Document**: Update this guide with actual findings and fixes applied

---

**Last Updated**: 2026-01-08

