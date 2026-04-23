# Populate SOURCE_PROD.OXFORD_ECONOMICS from datashare

**Context:** `SOURCE_PROD.OXFORD_ECONOMICS` is a **schema** (not a dataset). The **datasets** are the tables **AMREG** and **WDMARCO**. Data may land in `SOURCE_ENTITY.PRETIUM` from a datashare. This doc describes how to get that data into the schema dbt expects.

---

## Option A: Copy tables into SOURCE_PROD.OXFORD_ECONOMICS

If you want dbt to read from `SOURCE_PROD.OXFORD_ECONOMICS` (current `sources.yml` and cleaned models):

1. **Create the schema** (if it does not exist):

   ```sql
   USE DATABASE SOURCE_PROD;
   CREATE SCHEMA IF NOT EXISTS OXFORD_ECONOMICS;
   ```

2. **Copy AMREG** from the datashare location (e.g. SOURCE_ENTITY.PRETIUM):

   ```sql
   CREATE OR REPLACE TABLE SOURCE_PROD.OXFORD_ECONOMICS.AMREG
   AS SELECT * FROM SOURCE_ENTITY.PRETIUM.AMREG;
   ```

3. **Copy WDMARCO**:

   ```sql
   CREATE OR REPLACE TABLE SOURCE_PROD.OXFORD_ECONOMICS.WDMARCO
   AS SELECT * FROM SOURCE_ENTITY.PRETIUM.WDMARCO;
   ```

4. **Refresh going forward:** run the same `CREATE OR REPLACE TABLE ... AS SELECT` after the datashare is refreshed, or replace with an incremental pattern (e.g. task that truncates and inserts, or merge by a key) if your share is append-only.

A runnable script is in `scripts/sql/source_prod/copy_oxford_economics_from_entity.sql` (create and run when you have access to both SOURCE_ENTITY and SOURCE_PROD).

---

## Option B: Point dbt at the datashare (no copy)

If you prefer not to copy, point the Oxford source in `sources.yml` at the datashare:

- Set the **oxford_economics** source to `database: source_entity`, `schema: pretium`, with tables `AMREG` and `WDMARCO`.
- Ensure the role running dbt has read access to `SOURCE_ENTITY.PRETIUM`.
- The cleaned models already use quoted column names and work with the raw table shape.

Then you do not need `SOURCE_PROD.OXFORD_ECONOMICS` populated; the pipeline reads from SOURCE_ENTITY.PRETIUM.

---

## Summary

| Item | Meaning |
|------|--------|
| **OXFORD_ECONOMICS** | Schema (container) in SOURCE_PROD. |
| **AMREG, WDMARCO** | Datasets (tables); registered in DIM_DATASET; used as vendor_name in facts. |
| **Oxford Economics** | Vendor. |
