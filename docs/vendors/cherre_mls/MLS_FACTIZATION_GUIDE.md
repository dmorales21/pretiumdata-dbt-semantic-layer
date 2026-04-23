# MLS Data Factization Guide

## Overview

This guide explains how to factize MLS data from CLEANED to FACT layer using SnowSQL CLI.

## Prerequisites

1. **SnowSQL CLI installed** (see `docs/RULES_SNOWSQL_CLI_DEPLOYMENT.md`)
2. **Snowflake credentials configured** in `~/.snowsql/config`
3. **ACCOUNTADMIN role** or appropriate permissions:
   - `CREATE TABLE` on `TRANSFORM_PROD.FACT`
   - `SELECT` on `TRANSFORM_PROD.CLEANED`
   - `SELECT` on `ADMIN.CATALOG.DIM_DATASET`

## Quick Start

### Step 1: Verify CLEANED Data

```bash
# Check MLS data availability in CLEANED
snowsql -q "SELECT COUNT(*) FROM TRANSFORM_PROD.CLEANED.CLEANED_CHERRE_MLS_PRICING_ZIP WHERE DATE_REFERENCE >= '2024-01-01';"
```

### Step 2: Execute Factization Script

```bash
# Run the factization script
snowsql -f sql/factize_mls_data.sql
```

### Step 3: Verify FACT Data

The script includes verification queries that will show:
- Total rows loaded
- Unique geographies
- Unique metrics
- Date range coverage

## What Gets Factized

The script promotes the following MLS metrics from CLEANED to FACT:

1. **CHERRE_MLS_MEDIAN_LIST_PRICE_ZIP** - Median list price by ZIP (rent proxy)
2. **CHERRE_MLS_MEDIAN_PRICE_PER_SQFT_ZIP** - Median price per sqft
3. **CHERRE_MLS_ACTIVE_LISTINGS_ZIP** - Active listing count
4. **CHERRE_MLS_TOTAL_LISTINGS_ZIP** - Total listing count
5. **CHERRE_MLS_RENT_T3_CHANGE_PCT** - 3-month rent change percentage

## Data Quality Flags

The factization process adds quality flags:

- **VALID**: Data passes all quality checks
- **STALE**: Data is older than 90 days
- **OUTLIER**: Data falls outside 1st-99th percentile range
- **NULL**: Value is NULL

## Governance Metadata

The script enriches data with governance metadata from `ADMIN.CATALOG.DIM_DATASET`:

- `opco_access` - OpCo access level
- `team_access` - Team access level
- `access_tier` - Access tier (INTERNAL, EXTERNAL, etc.)
- `sensitivity_level` - Data sensitivity (LOW, MEDIUM, HIGH)
- `geo_coverage_count` - Number of unique geographies per date/vendor
- `required_dimensions` - JSON array of required dimensions

## Integration with Tenancy Tradeoff Signal

Once MLS data is factized, the `FCT_TENANCY_TRADEOFF_SIGNAL` model can use it as the primary source:

```sql
-- The signal model will automatically use MLS data when available
-- Primary: MLS median list price (more accurate)
-- Fallback: Zillow ZORI (when MLS not available)
```

## Troubleshooting

### Issue: Permission Denied

```sql
-- Grant necessary permissions
GRANT USAGE ON DATABASE TRANSFORM_PROD TO ROLE YOUR_ROLE;
GRANT USAGE ON SCHEMA TRANSFORM_PROD.FACT TO ROLE YOUR_ROLE;
GRANT CREATE TABLE ON SCHEMA TRANSFORM_PROD.FACT TO ROLE YOUR_ROLE;
GRANT SELECT ON ALL TABLES IN SCHEMA TRANSFORM_PROD.CLEANED TO ROLE YOUR_ROLE;
```

### Issue: No Data in CLEANED

Check if CLEANED models have been run:

```bash
# Check CLEANED table exists and has data
snowsql -q "SELECT COUNT(*) FROM TRANSFORM_PROD.CLEANED.CLEANED_CHERRE_MLS_PRICING_ZIP;"
```

### Issue: Table Already Exists

The script uses `CREATE OR REPLACE TABLE`, so it will overwrite existing tables. If you need to preserve existing data, modify the script to use `INSERT` with incremental logic.

## Next Steps

After factization:

1. **Update HOUSING_HOU_PRICING_ALL_TS**: Ensure MLS data is included in the union
2. **Update Tenancy Tradeoff Signal**: Model will automatically use MLS data
3. **Verify Coverage**: Check CBSA coverage expansion
4. **Monitor Quality**: Review quality flags and completeness metrics

## References

- `sql/factize_mls_data.sql` - Factization script
- `docs/RULES_SNOWSQL_CLI_DEPLOYMENT.md` - SnowSQL CLI usage guide
- `models/analytics_prod/scores/fct_tenancy_tradeoff_signal.sql` - Signal model using MLS data

