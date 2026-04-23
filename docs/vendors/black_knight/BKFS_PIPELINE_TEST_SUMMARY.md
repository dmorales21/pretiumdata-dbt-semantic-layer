# BKFS Pipeline Test Summary

**Date**: 2026-01-29  
**Status**: ✅ **PARTIALLY COMPLETE** - Core pipeline working, STATE column issue in time series models

---

## ✅ Completed Tasks

### 1. Data Extraction & Loading
- ✅ **LOANLOOKUP**: 243 rows loaded from S3 to Snowflake
- ✅ **LOAN**: 400 rows loaded from Redshift to Snowflake  
- ✅ **LOANMONTH**: 2,000 rows loaded from Redshift to Snowflake
- ✅ S3 stage and file format configured for `s3://pret-ai-general/sources/BLACK_KNIGHT/`

### 2. Cleaned Models
- ✅ **cleaned_bkfs_loan**: Successfully running, 400 rows processed
- ❌ **cleaned_bkfs_loanmonth_ts**: STATE column resolution error (see Issues below)
- ❌ **cleaned_bkfs_property**: STATE column resolution error (see Issues below)

### 3. Metric Registration
- ✅ Schema metadata file created: `models/20_cleaned/schema_bkfs.yml`
- ✅ Manual registration SQL created: `sql/admin/catalog/register_bkfs_metrics.sql`
- ⏳ **PENDING**: Execute registration SQL in Snowflake

---

## ❌ Known Issues

### Issue 1: STATE Column Resolution Error

**Error**: `SQL compilation error: invalid identifier 'STATE'`

**Affected Models**:
- `cleaned_bkfs_loanmonth_ts`
- `cleaned_bkfs_property`

**Root Cause**: 
The `state` column exists in the source tables and is properly selected through the CTE chain:
- `source_data` → has `state`
- `zip_normalized` → `SELECT *` includes `state`
- `month_to_date` → `SELECT *` should include `state` (explicitly listed now)
- `unpivoted` → all UNION ALL branches include `state`
- Final SELECT → references `state::VARCHAR AS state_code`

**Attempted Fixes**:
1. ✅ Explicitly listed all columns in `month_to_date` CTE
2. ✅ Verified all UNION ALL branches have `state` column
3. ✅ Removed CTE alias (`u.state` → `state`)
4. ✅ Changed CAST syntax (`CAST(u.state AS VARCHAR)` → `state::VARCHAR`)

**Next Steps**:
- Test query directly in Snowflake to isolate the issue
- Check if there's a reserved word conflict with `STATE`
- Consider using double quotes: `"state"::VARCHAR`
- Verify column exists in actual data: `SELECT DISTINCT state FROM SOURCE_PROD.BKFS.LOANMONTH LIMIT 5`

---

## 📊 Data Verification

### Row Counts
```sql
-- Source Tables
SELECT 'LOAN' AS table_name, COUNT(*) AS row_count FROM SOURCE_PROD.BKFS.LOAN
UNION ALL
SELECT 'LOANMONTH', COUNT(*) FROM SOURCE_PROD.BKFS.LOANMONTH
UNION ALL
SELECT 'LOANLOOKUP', COUNT(*) FROM SOURCE_PROD.BKFS.LOANLOOKUP;

-- Results:
-- LOAN: 400 rows
-- LOANMONTH: 2,000 rows  
-- LOANLOOKUP: 243 rows
```

### Cleaned Tables
```sql
-- Cleaned Tables
SELECT 'cleaned_bkfs_loan' AS table_name, COUNT(*) AS row_count FROM CLEANED.CLEANED_BKFS_LOAN;
-- Result: 400 rows ✅
```

---

## 🎯 Next Steps

### Immediate (Required)
1. **Fix STATE Column Issue**
   - Test direct query: `SELECT state FROM SOURCE_PROD.BKFS.LOANMONTH LIMIT 5`
   - Try quoted identifier: `"state"::VARCHAR`
   - Check for reserved word conflicts

2. **Register Metrics**
   - Execute: `sql/admin/catalog/register_bkfs_metrics.sql` in Snowflake
   - Verify: `SELECT * FROM ADMIN.CATALOG.DIM_METRIC WHERE METRIC_VENDOR_NAME = 'BKFS'`

3. **Complete Cleaned Models**
   - Fix `cleaned_bkfs_loanmonth_ts`
   - Fix `cleaned_bkfs_property`
   - Verify row counts match source data

### Follow-up (Optional)
4. **Load Full Dataset**
   - Extract all BKFS tables from Redshift to S3
   - Load into Snowflake using COPY INTO
   - Run full cleaned model pipeline

5. **Run Feature Models**
   - `feature_bkfs_delinquency_metrics`
   - `feature_bkfs_foreclosure_metrics`
   - `feature_bkfs_property_metrics`
   - `feature_bkfs_credit_metrics`

6. **Run Signal Models**
   - `fct_delinquency_risk_signal`
   - `fct_distressed_opportunity_signal`
   - `fct_loan_performance_signal`

---

## 📝 Files Created/Modified

### New Files
- `scripts/bkfs/load_loanlookup_to_snowflake.py` - Load loanlookup from S3
- `scripts/bkfs/load_sample_data.py` - Load sample data from Redshift
- `models/20_cleaned/schema_bkfs.yml` - Catalog metadata
- `sql/admin/catalog/register_bkfs_metrics.sql` - Manual metric registration
- `docs/BKFS_PIPELINE_TEST_SUMMARY.md` - This file

### Modified Files
- `models/20_cleaned/cleaned_bkfs_loanmonth_ts.sql` - Explicit column listing in month_to_date
- `models/20_cleaned/cleaned_bkfs_property.sql` - Explicit column listing in month_to_date

---

## ✅ Success Criteria Met

- [x] Test data loaded into Snowflake source tables
- [x] `cleaned_bkfs_loan` model running successfully
- [x] Metric registration SQL prepared
- [ ] `cleaned_bkfs_loanmonth_ts` model running (BLOCKED: STATE issue)
- [ ] `cleaned_bkfs_property` model running (BLOCKED: STATE issue)
- [ ] Metrics registered in ADMIN.CATALOG.DIM_METRIC

---

**Last Updated**: 2026-01-29 16:16 EST

