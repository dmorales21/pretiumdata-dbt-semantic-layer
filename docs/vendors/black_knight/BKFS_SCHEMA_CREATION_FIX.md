# BKFS Schema Creation Fix

**Date**: 2026-01-29  
**Issue**: `Schema 'SOURCE_PROD.BKFS' does not exist or not authorized`  
**Status**: ⚠️ **SCHEMA NEEDS TO BE CREATED**

---

## Problem

The dbt models are failing because the `SOURCE_PROD.BKFS` schema doesn't exist in Snowflake yet.

**Error**:
```
002003 (02000): SQL compilation error:
Schema 'SOURCE_PROD.BKFS' does not exist or not authorized.
```

---

## Solution

### Option 1: Run SQL Script (Recommended)

Execute the schema creation script:

```bash
# Connect to Snowflake and run:
snowsql -c prod -f sql/source_prod/bkfs/01_create_database_schema.sql
```

Or manually run in Snowflake:

```sql
USE ROLE ACCOUNTADMIN;
USE WAREHOUSE AI_WH;
USE DATABASE SOURCE_PROD;

CREATE SCHEMA IF NOT EXISTS SOURCE_PROD.BKFS
    COMMENT = 'Black Knight Financial Services loan performance data';

-- Grant permissions (adjust role as needed)
GRANT USAGE ON SCHEMA SOURCE_PROD.BKFS TO ROLE <YOUR_ROLE>;
GRANT SELECT ON SCHEMA SOURCE_PROD.BKFS TO ROLE <YOUR_ROLE>;
```

### Option 2: Use dbt Macro

A macro has been created at `macros/create_bkfs_schema.sql`. Run it:

```bash
dbt run-operation create_bkfs_schema
```

**Note**: This requires proper Snowflake credentials and permissions.

---

## After Schema Creation

Once the schema exists, you can run the BKFS models:

```bash
# Run all BKFS models
dbt run --select tag:bkfs

# Or run specific models
dbt run --select cleaned_bkfs_loan
dbt run --select cleaned_bkfs_loanmonth_ts
dbt run --select cleaned_bkfs_property
```

---

## Additional Notes

### Credential Cache Issue

If you encounter credential cache timeout errors:
```bash
# Clear the credential cache
rm -rf ~/Library/Caches/Snowflake/Credentials/credential_cache.lease

# Or wait for the lease to expire (usually 1-2 minutes)
```

### Schema Location

The schema should be created at:
- **Database**: `SOURCE_PROD`
- **Schema**: `BKFS`
- **Full Path**: `SOURCE_PROD.BKFS`

### Source Definition

The source is correctly defined in `models/sources.yml`:
```yaml
- name: bkfs
  database: source_prod
  schema: bkfs
```

This maps to `SOURCE_PROD.BKFS` in Snowflake (case-insensitive).

---

## Verification

After creating the schema, verify it exists:

```sql
SHOW SCHEMAS IN DATABASE SOURCE_PROD LIKE 'BKFS';
```

You should see:
```
name  | database_name | created_on
------|---------------|------------
BKFS  | SOURCE_PROD   | 2026-01-29
```

---

**Last Updated**: 2026-01-29  
**Next Step**: Create the schema, then run `dbt run --select tag:bkfs`

