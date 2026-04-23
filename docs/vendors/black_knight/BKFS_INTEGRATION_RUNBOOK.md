# BKFS Snowflake Integration Runbook

**Last Updated**: 2026-01-27  
**Status**: ✅ **IMPLEMENTATION COMPLETE**  
**Database**: `SOURCE_PROD.BKFS`  
**Source**: Redshift `extdata.bkfs` → S3 → Snowflake

---

## Overview

This runbook documents the complete integration of Black Knight Financial Services (BKFS) loan performance data from Redshift into Snowflake. The integration includes:

- **14 BKFS tables** (~26.8 billion rows total)
- **Monthly scheduled updates** via automated pipeline
- **Full dbt transformation** (SOURCE → CLEANED → FACT layers)
- **Python + S3 + Snowflake** architecture

---

## Architecture

```
Redshift (extdata.bkfs)
    ↓ [Python UNLOAD]
S3 (pret-ai-general/sources/BKFS/)
    ↓ [Snowflake COPY INTO]
SOURCE_PROD.BKFS (raw tables)
    ↓ [dbt cleaned models]
TRANSFORM_PROD.CLEANED (normalized)
    ↓ [dbt fact models]
TRANSFORM_PROD.FACT (canonical fact tables)
```

---

## Prerequisites

### 1. VPN Connection
- **Required**: Connect to GlobalProtect VPN
- **URL**: https://newvpn.pretiumpartnersllc.com
- **Verification**: `ping dbred.spark.rcf.pretium.com`

### 2. Python Environment
```bash
# Activate virtual environment
source venv/bin/activate

# Install required packages
pip install redshift-connector boto3 pandas pyarrow python-dotenv
```

### 3. Environment Variables
```bash
# Redshift
export REDSHIFT_HOST=dbred.spark.rcf.pretium.com
export REDSHIFT_PORT=5439
export REDSHIFT_DATABASE=extdata
export REDSHIFT_SCHEMA=bkfs
export REDSHIFT_USER=aposes
export REDSHIFT_PASSWORD=aJ9c9Ne$3^1

# AWS S3
export AWS_ACCESS_KEY_ID=your_key
export AWS_SECRET_ACCESS_KEY=your_secret
export AWS_REGION=us-east-1
export S3_BUCKET=pret-ai-general
export S3_PREFIX=sources/BKFS

# Optional: Redshift IAM Role for UNLOAD
export REDSHIFT_IAM_ROLE=arn:aws:iam::...
```

### 4. Snowflake Permissions
```sql
GRANT USAGE ON DATABASE SOURCE_PROD TO ROLE ACCOUNTADMIN;
GRANT CREATE SCHEMA ON DATABASE SOURCE_PROD TO ROLE ACCOUNTADMIN;
GRANT CREATE STAGE ON SCHEMA SOURCE_PROD.BKFS TO ROLE ACCOUNTADMIN;
```

---

## Data Tables

| Table | Rows | Type | Description |
|-------|------|------|-------------|
| `loan` | 242,090,000 | Static | Core loan characteristics |
| `loanmonth` | 10,347,626,418 | Time Series | Monthly performance snapshots |
| `loancurrent` | 242,090,000 | Static | Current loan status |
| `property` | 10,112,267,020 | Time Series | Property-level data |
| `heloc` | 1,515,520,776 | Time Series | HELOC loan data |
| `loss_mitigation` | 4,494,646,119 | Time Series | Loss mitigation records |
| `loandelinquencyhistory` | 242,090,000 | Static | Delinquency history |
| `property_enh` | 241,727,132 | Static | Enhanced property data |
| `loanarm` | 27,836,808 | Static | ARM loan data |
| `loss_mitigation_fb` | 1,769,440,975 | Time Series | Forbearance records |
| `loss_mitigation_mod` | 4,435,881 | Static | Modification records |
| `resolution` | 3,688,710 | Static | Loan resolution data |
| `loanlookup` | 243 | Static | Lookup reference |
| `view_dq_buyout_adj` | 96 | Static | Buyout adjustment |

**Total: ~26.8 billion rows**

---

## Execution Steps

### Phase 1: Extract from Redshift to S3

```bash
# Run extraction script
python scripts/bkfs/extract_bkfs_to_s3.py

# Or extract specific table
python scripts/bkfs/extract_bkfs_to_s3.py --table loanlookup

# Or incremental extraction (for time-series tables)
python scripts/bkfs/extract_bkfs_to_s3.py --incremental
```

**Expected Output:**
- Parquet files in `s3://pret-ai-general/sources/BKFS/{table_name}/YYYY-MM-DD/`
- Files compressed with Snappy
- Multiple part files for large tables (max 1 GB per file)

**Verification:**
```bash
aws s3 ls s3://pret-ai-general/sources/BKFS/ --recursive
```

---

### Phase 2: Create Snowflake Infrastructure

Execute SQL scripts in Snowflake in order:

```sql
-- 1. Create schema
@sql/source_prod/bkfs/01_create_database_schema.sql

-- 2. Create S3 stages and file formats
@sql/source_prod/bkfs/02_create_s3_stages.sql

-- 3. Create tables
@sql/source_prod/bkfs/03_create_tables.sql
```

**Note**: Update `AWS_S3_INTEGRATION` in step 2 with your actual storage integration name.

---

### Phase 3: Load Data from S3 to Snowflake

```sql
-- Load all tables from S3
@sql/source_prod/bkfs/04_load_from_s3.sql
```

**Expected Duration:**
- Small tables (<1M rows): < 1 minute
- Medium tables (1M-100M rows): 5-30 minutes
- Large tables (>100M rows): 30 minutes - 2 hours
- Very large tables (>1B rows): 2-8 hours

**Monitor Progress:**
```sql
-- Check load status
SELECT 
    table_name,
    COUNT(*) AS row_count,
    MIN(_extract_date) AS earliest_extract,
    MAX(_extract_date) AS latest_extract
FROM (
    SELECT 'LOAN' AS table_name, COUNT(*), MIN(_extract_date), MAX(_extract_date) FROM SOURCE_PROD.BKFS.LOAN
    UNION ALL
    SELECT 'LOANMONTH', COUNT(*), MIN(_extract_date), MAX(_extract_date) FROM SOURCE_PROD.BKFS.LOANMONTH
    -- ... other tables
)
GROUP BY table_name;
```

---

### Phase 4: Validate Data Load

```sql
-- Run validation queries
@sql/source_prod/bkfs/05_validate_load.sql
```

**Validation Checks:**
- ✅ Row count matches Redshift (within 1% tolerance)
- ✅ Date ranges are valid
- ✅ Key columns are not null
- ✅ Delinquency rates are reasonable (0-50%)
- ✅ Geography coverage (50+ states)

---

### Phase 5: Run dbt Models (Clean + Factize)

**Recommended order** (cleaned → fact → canonical → union):

```bash
# 1) Cleaned layer (source → cleaned)
dbt run --select cleaned_bkfs_loan cleaned_bkfs_loanmonth_ts cleaned_bkfs_property

# 2) Fact layer + canonical (run together so ref() in capital_cap_debt_bkfs resolves to same schema)
dbt run --select fact_bkfs_loan_characteristics fact_bkfs_loan_performance capital_cap_debt_bkfs

# 3) Optional: capital debt union (needs Cherre if running full union)
dbt run --select +capital_cap_debt_all_ts
```

**One-shot (all BKFS from cleaned through canonical view):**
```bash
dbt run --select cleaned_bkfs_loan+   # cleaned and all downstream (fact + capital_cap_debt_bkfs)
# Or by tag:
dbt run --select tag:bkfs
```

**Robust phased run (recommended when debugging failures):**  
Use the script that runs in phases with clear start/success/fail messaging and a timestamped log. It reports exactly which phase failed and prints the last 30 lines of the log.
```bash
# Full chain (compile check, then cleaned → fact → canonical)
./scripts/bkfs/run_bkfs_dbt_chain.sh

# Compile-only (no Snowflake)
./scripts/bkfs/run_bkfs_dbt_chain.sh --compile

# Single phase (e.g. after fixing, re-run from fact layer)
./scripts/bkfs/run_bkfs_dbt_chain.sh --phase 2
```
Logs: `logs/bkfs/bkfs_dbt_chain_<timestamp>.log`. Set `DBT_DB` and `DBT_SCHEMA` if needed (defaults: `TRANSFORM_PROD`, `PUBLIC`).

**Expected Output:**
- `TRANSFORM_PROD.CLEANED.CLEANED_BKFS_LOAN`
- `TRANSFORM_PROD.CLEANED.CLEANED_BKFS_LOANMONTH_TS`
- `TRANSFORM_PROD.CLEANED.CLEANED_BKFS_PROPERTY`
- `TRANSFORM_PROD.FACT.FACT_BKFS_LOAN_CHARACTERISTICS` (incremental table)
- `TRANSFORM_PROD.FACT.FACT_BKFS_LOAN_PERFORMANCE` (view)
- `TRANSFORM_PROD.FACT.CAPITAL_CAP_DEBT_BKFS` (canonical BKFS table)

**Canonical BKFS table (work with BKFS in one place):**
- **Model:** `capital_cap_debt_bkfs` → `TRANSFORM_PROD.FACT.CAPITAL_CAP_DEBT_BKFS`
- **Purpose:** Single canonical table for all BKFS loan characteristics and loan performance metrics (same schema as `capital_cap_debt_all_ts`). Use this for signals, BI, or analytics.
- **Build order:** Run `fact_bkfs_loan_characteristics` and `fact_bkfs_loan_performance` first, then `capital_cap_debt_bkfs` (or `dbt run --select capital_cap_debt_bkfs` after fact models).
- **Union:** BKFS is also included in `capital_cap_debt_all_ts` alongside Cherre recorder; filter by `vendor_name = 'BKFS'` or use `capital_cap_debt_bkfs` for BKFS-only use cases.

**Estimated runtime (full BKFS dbt chain)**  
Run `dbt run --select cleaned_bkfs_loan+` (or the phased commands in Phase 5) in an environment with a **stable Snowflake connection**. Approximate duration:

| Segment | Models | Est. runtime |
|--------|--------|--------------|
| Cleaned layer | `cleaned_bkfs_loan`, `cleaned_bkfs_loanmonth_ts`, `cleaned_bkfs_property` | 15–45+ min (dominated by `cleaned_bkfs_loanmonth_ts` and `cleaned_bkfs_property` on 10B+ row sources) |
| Fact layer | `fact_bkfs_loan_performance` (view), `fact_bkfs_loan_characteristics` (incremental) | 2–15 min |
| Canonical | `capital_cap_debt_bkfs` (view) | &lt; 2 min |
| **Full chain** | `cleaned_bkfs_loan+` | **~20–60+ min** (warehouse size and data volume dependent) |

---

### Verification (dbt compile vs run)

- **Compile:** The BKFS dbt models have been verified to **compile successfully** (no SQL/syntax errors). You can confirm locally with:
  ```bash
  DBT_DB=TRANSFORM_PROD DBT_SCHEMA=PUBLIC dbt compile --select cleaned_bkfs_loan+ 
  ```
- **Run:** A full **run** executes against Snowflake and requires a **stable Snowflake connection**. If you see SSL/connection timeouts or retries, run the same `dbt run` from a machine or CI environment with reliable network access to Snowflake (e.g. VPN, corporate network, or dbt Cloud). Compile success does not guarantee run success if the connection is unstable.

---

### Factize status and validation

**Core BKFS chain (6 models, in run order):**

| # | Model | Materialization | What “SUCCESS” / “SUCCESS 0” means |
|---|--------|------------------|-------------------------------------|
| 1 | `cleaned_bkfs_loan` | table | SUCCESS = table created/refreshed. |
| 2 | `cleaned_bkfs_loanmonth_ts` | incremental | SUCCESS = merge ran. **SUCCESS 0** = 0 rows merged (no new data or all filtered out) — **not a failure**. |
| 3 | `cleaned_bkfs_property` | incremental | Same as above. |
| 4 | `fact_bkfs_loan_characteristics` | incremental | SUCCESS = merge ran. First run creates the fact table from `cleaned_bkfs_loan`. |
| 5 | `fact_bkfs_loan_performance` | view | SUCCESS = view created. |
| 6 | `capital_cap_debt_bkfs` | view | SUCCESS = canonical BKFS view created; factization complete. |

**Validate the rest of the status:**

1. **From your run output:** Confirm each of the 6 models above appears with `OK` / `SUCCESS`. If your run was “8 of 8”, the extra 2 may be downstream (e.g. `capital_cap_debt_all_ts`) or other selected nodes.
2. **From last run’s artifacts:**  
   `./scripts/bkfs/validate_bkfs_factize_status.sh`  
   (reads `target/run_results.json` and prints a BKFS-only status table; pass a path to another run’s `run_results.json` if needed.)
3. **In Snowflake:** After a successful run, confirm objects and row counts:
   - `TRANSFORM_PROD.CLEANED.CLEANED_BKFS_LOAN` (table)
   - `TRANSFORM_PROD.CLEANED.CLEANED_BKFS_LOANMONTH_TS` (table)
   - `TRANSFORM_PROD.CLEANED.CLEANED_BKFS_PROPERTY` (table)
   - `TRANSFORM_PROD.FACT.FACT_BKFS_LOAN_CHARACTERISTICS` (table)
   - `TRANSFORM_PROD.FACT.FACT_BKFS_LOAN_PERFORMANCE` (view)
   - `TRANSFORM_PROD.FACT.CAPITAL_CAP_DEBT_BKFS` (view)

**Blockers to factizing BKFS:**

| Blocker | Symptom | What to do |
|--------|---------|------------|
| **fact_bkfs_loan_characteristics fails** | Error on merge or “relation does not exist” | First run: ensure `cleaned_bkfs_loan` succeeded and has rows with `geo_id IS NOT NULL`. Re-run with `--full-refresh` only if you intend to rebuild the incremental from scratch. |
| **capital_cap_debt_bkfs fails** | Error on UNION or column mismatch | Both fact models must succeed first. Check that `fact_bkfs_loan_characteristics` and `fact_bkfs_loan_performance` expose the same column list as in `capital_cap_debt_bkfs.sql`. |
| **Empty fact tables** | SUCCESS but 0 rows in fact | If `cleaned_bkfs_loan` has no rows with non-null `geo_id`, the fact will be empty. Check source LOAN and cleaned output row counts and filters. |
| **admin_catalog_available** | Fewer rows or different GEO_KEYs | With `admin_catalog_available: true`, fact uses `ADMIN.CATALOG.DIM_GEOGRAPHY`; with `false`, uses synthetic `HASH(geo_id \|\| geo_level_code)`. Ensure DIM_GEOGRAPHY is populated for BKFS geos if you rely on the catalog. |
| **capital_cap_debt_bkfs: "Object … FACT.FACT_BKFS_LOAN_CHARACTERISTICS does not exist"** | Fact table was created in `PUBLIC_fact` (Phase 2) but the canonical view (Phase 3) looks in `FACT` when run in a **separate** dbt invocation. | Run **fact and canonical in one dbt run** so `ref()` resolves to the same schema. Use `./scripts/bkfs/run_bkfs_dbt_chain.sh` (it runs fact + canonical in a single Phase 2), or run: `dbt run --select fact_bkfs_loan_characteristics fact_bkfs_loan_performance capital_cap_debt_bkfs` in one go. |

---

### Phase 6: Set Up Monthly Automation

```sql
-- Create Snowflake tasks
@sql/source_prod/bkfs/06_create_snowflake_tasks.sql

-- Enable tasks (after testing)
ALTER TASK SOURCE_PROD.BKFS.TASK_MONTHLY_BKFS_REFRESH RESUME;
ALTER TASK SOURCE_PROD.BKFS.TASK_VALIDATE_BKFS_LOAD RESUME;
```

**Schedule**: 1st of month at 2 AM Eastern Time

**Or use orchestration script:**
```bash
./scripts/bkfs/orchestrate_bkfs_pipeline.sh
```

---

## Monthly Refresh Process

### Automated (Recommended)

1. **Snowflake Task** runs on 1st of month at 2 AM ET
2. **Stored Procedure** executes COPY INTO for all tables
3. **Validation Task** runs after load completes
4. **dbt Models** run via external orchestration (Airflow, dbt Cloud, etc.)

### Manual

1. Run extraction: `python scripts/bkfs/extract_bkfs_to_s3.py`
2. Load to Snowflake: Execute `04_load_from_s3.sql`
3. Validate: Execute `05_validate_load.sql`
4. Run dbt: `dbt run --select bkfs*`

---

## Troubleshooting

### Issue: "Connection reset by peer" during extraction

**Solution:**
1. Verify VPN is connected
2. Test network: `ping dbred.spark.rcf.pretium.com`
3. Check Redshift credentials
4. Try smaller table first: `--table loanlookup`

### Issue: "Permission denied for schema" in Snowflake

**Solution:**
1. Verify database: `SOURCE_PROD` (not `PROD`)
2. Verify schema: `BKFS`
3. Check role permissions: `SHOW GRANTS TO ROLE ACCOUNTADMIN`

### Issue: "No files found in S3" after UNLOAD

**Solution:**
1. Check Redshift IAM role permissions
2. Verify S3 bucket path: `s3://pret-ai-general/sources/BKFS/`
3. Check UNLOAD command syntax
4. Verify AWS credentials

### Issue: "COPY INTO failed" in Snowflake

**Solution:**
1. Check stage exists: `SHOW STAGES LIKE 'STG_BKFS%'`
2. Verify file format: `SHOW FILE FORMATS LIKE 'FF_BKFS%'`
3. Check S3 access: `LIST @STG_BKFS_S3 LIMIT 10`
4. Review error details: Check `COPY INTO` error messages

### Issue: Large table loads timeout

**Solution:**
1. Load in batches by date range
2. Increase warehouse size: `USE WAREHOUSE LARGE_WH`
3. Load during off-peak hours
4. Use `FORCE = FALSE` to skip already-loaded files

---

## Data Quality Checks

### Row Count Validation

```sql
SELECT 
    'LOAN' AS table_name,
    COUNT(*) AS snowflake_count,
    242090000 AS expected_count,
    ROUND(COUNT(*) * 100.0 / 242090000, 2) AS pct_of_expected
FROM SOURCE_PROD.BKFS.LOAN;
```

### Date Range Validation

```sql
SELECT 
    MIN(asofmonth) AS earliest_month,
    MAX(asofmonth) AS latest_month,
    COUNT(DISTINCT asofmonth) AS distinct_months
FROM SOURCE_PROD.BKFS.LOANMONTH;
```

### Delinquency Rate Check

```sql
SELECT 
    state,
    COUNT(*) AS total_loans,
    COUNT(CASE WHEN delinquencystatus > 0 THEN 1 END) AS delinquent_loans,
    ROUND(COUNT(CASE WHEN delinquencystatus > 0 THEN 1 END) * 100.0 / COUNT(*), 2) AS dq_rate_pct
FROM SOURCE_PROD.BKFS.LOANMONTH
WHERE asofmonth = (SELECT MAX(asofmonth) FROM SOURCE_PROD.BKFS.LOANMONTH)
GROUP BY state
ORDER BY dq_rate_pct DESC;
```

---

## File Structure

```
pretium-ai-dbt/
├── scripts/bkfs/
│   ├── extract_bkfs_to_s3.py          # Extraction script
│   ├── config.yml                      # Configuration file
│   ├── orchestrate_bkfs_pipeline.sh   # Full ETL orchestration
│   └── run_bkfs_dbt_chain.sh          # dbt-only phased run (robust messaging + logs)
├── sql/source_prod/bkfs/
│   ├── 01_create_database_schema.sql  # Schema creation
│   ├── 02_create_s3_stages.sql        # S3 stages
│   ├── 03_create_tables.sql           # Table DDL
│   ├── 04_load_from_s3.sql            # COPY INTO commands
│   ├── 05_validate_load.sql           # Validation queries
│   └── 06_create_snowflake_tasks.sql  # Automation tasks
├── models/
│   ├── sources.yml                     # BKFS source definitions
│   ├── 20_cleaned/
│   │   ├── cleaned_bkfs_loan.sql
│   │   ├── cleaned_bkfs_loanmonth_ts.sql
│   │   └── cleaned_bkfs_property.sql
│   └── 30_fact/
│       ├── fact_bkfs_loan_performance.sql
│       └── fact_bkfs_loan_characteristics.sql
└── docs/
    └── BKFS_INTEGRATION_RUNBOOK.md    # This file
```

---

## Support Contacts

- **IT Support**: Derek Baxter (dbaxter@progressresidential.com)
- **Database Admin**: Doug Miller (dmiller@progressresidential.com)
- **Alternative Contact**: Spencer Dobbs (sdobbs@progressresidential.com)

---

## Key Metrics

### Loan Performance Metrics
- Principal balance (monthly)
- Interest rate (monthly)
- Delinquency status (monthly)
- Remaining term (monthly)
- Credit score (monthly)

### Loan Characteristics
- Original loan amount
- Original interest rate
- Loan term (months)
- Property value
- CLTV/LTV ratios
- Credit score at origination

### Geography Coverage
- 50+ states
- 20,000+ ZIP codes
- CBSA/Metro division coverage

---

## Next Steps

1. ✅ **Initial Load**: Complete first-time data load
2. ✅ **Validation**: Run all validation queries
3. ✅ **dbt Models**: Build cleaned and fact tables
4. ✅ **Automation**: Set up monthly Snowflake tasks
5. 📋 **Monitoring**: Set up alerts for failed loads
6. 📋 **Documentation**: Update data catalog with BKFS metrics
7. 📋 **Analytics**: Create loan performance dashboards

---

## Appendix

### S3 Structure
```
s3://pret-ai-general/sources/BKFS/
├── loan/YYYY-MM-DD/
│   ├── loan_part0000.parquet
│   ├── loan_part0001.parquet
│   └── ...
├── loanmonth/YYYY-MM-DD/
│   ├── loanmonth_part0000.parquet
│   └── ...
└── ...
```

### Snowflake Schema
```
SOURCE_PROD.BKFS
├── LOAN
├── LOANMONTH
├── LOANCURRENT
├── PROPERTY
├── HELOC
├── LOSS_MITIGATION
├── LOANDELINQUENCYHISTORY
├── PROPERTY_ENH
├── LOANARM
├── LOSS_MITIGATION_FB
├── LOSS_MITIGATION_MOD
├── RESOLUTION
├── LOANLOOKUP
└── VIEW_DQ_BUYOUT_ADJ
```

### dbt Models
```
TRANSFORM_PROD.CLEANED
├── CLEANED_BKFS_LOAN
├── CLEANED_BKFS_LOANMONTH_TS
└── CLEANED_BKFS_PROPERTY

TRANSFORM_PROD.FACT
├── FACT_BKFS_LOAN_CHARACTERISTICS   (incremental)
├── FACT_BKFS_LOAN_PERFORMANCE       (view)
├── CAPITAL_CAP_DEBT_BKFS            (canonical BKFS; feeds capital_cap_debt_all_ts)
└── CAPITAL_CAP_DEBT_ALL_TS          (union: Cherre + BKFS)
```

---

**Last Updated**: 2026-01-27

