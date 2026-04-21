# Vet: catalog-only vendors (`vet_catalog_only_vendors_pretium.sql`)

**Run:** `snowsql -c pretium -o output_format=tsv -o header=true -f scripts/sql/migration/vet_catalog_only_vendors_pretium.sql`  
**Role observed:** `ACCOUNTADMIN`  
**Date:** 2026-04-18

## Row counts and stats (from script)

| probe | field | value |
| --- | --- | --- |
| CYBERSYN_OBJECT_COUNT | n | 106 |
| FBI_CRIME_TIMESERIES_STATS | row_cnt | 21232 |
| FBI_CRIME_TIMESERIES_STATS | distinct_geo | 52 |
| FBI_CRIME_TIMESERIES_STATS | distinct_variable | 10 |
| FBI_CRIME_TIMESERIES_STATS | min_date | 1979-12-31 |
| FBI_CRIME_TIMESERIES_STATS | max_date | 2023-12-31 |
| FBI_CRIME_TIMESERIES_STATS | null_value_rows | 0 |
| SOURCE_PROD_FDIC_CONSTRUCTION | row_cnt | 0 |

`SHOW TABLES IN SCHEMA SOURCE_ENTITY.PROGRESS` returned **no rows** in the TSV-captured snowsql run (listing vs role). **`SOURCE_ENTITY.INFORMATION_SCHEMA.TABLES`** where `table_schema = 'PROGRESS'` reports **381** tables for the same session — use `INFORMATION_SCHEMA` or qualified `SHOW` when reconciling.

## `GLOBAL_GOVERNMENT.CYBERSYN.CYBERSYN_DATA_CATALOG` (skipped-vendor domains)

Catalog lists (among others): `fbi_crime_*`, `fdic_*`, `usps_address_change_*`, `financial_cfpb_complaint*`, multiple `noaa_*` tables. **NOAA names do not appear** in `GLOBAL_GOVERNMENT.INFORMATION_SCHEMA.TABLES` for schema `CYBERSYN` in this account (0 rows for `NOAA%`, `NWRFC`, `WEATHER` filters) — only a subset of catalog entries are mounted as consumable objects here.

## Cybersyn access: FBI vs FDIC / USPS / CFPB / NOAA

| object (example) | `SELECT` as `ACCOUNTADMIN` | `GRANT SELECT … TO ROLE SYSADMIN` |
| --- | --- | --- |
| `GLOBAL_GOVERNMENT.CYBERSYN.FBI_CRIME_TIMESERIES` | **Allowed** (count 21232) | n/a (already usable) |
| `GLOBAL_GOVERNMENT.CYBERSYN.FDIC_SUMMARY_OF_DEPOSITS_TIMESERIES` | **Denied** (`002003` does not exist or not authorized) | **Denied** (same error) |
| `GLOBAL_GOVERNMENT.CYBERSYN.USPS_ADDRESS_CHANGE_TIMESERIES` | **Denied** | not attempted (same pattern as FDIC) |

**Conclusion:** Extending **`SELECT`** on FDIC / USPS / CFPB / NOAA Cybersyn objects to match FBI is **not something this consumer account can do with local `GRANT`**. FBI is provisioned on the inbound share; other domains are visible in **`CYBERSYN_DATA_CATALOG`** (and partially in **`INFORMATION_SCHEMA`**) but **row access** is withheld. **Next step:** account / data share admin requests **Cybersyn (or the share owner)** to add the same entitlement class as FBI for the needed objects (or confirms intentional restriction).

## Salesforce / CRM landing

| location | tables visible (`INFORMATION_SCHEMA.TABLES`) | notes |
| --- | ---: | --- |
| `DS_SOURCE_PROD_SFDC.SFDC_SHARE` | **283** | Legacy Salesforce share — matches `source('salesforce', …)` in pretium-ai-dbt `sources.yml` (`database: DS_SOURCE_PROD_SFDC`, `schema: SFDC_SHARE`). |
| `SOURCE_ENTITY.PROGRESS` | **381** | Large operational / Progress-adjacent schema; not a substitute for the legacy SFDC share. Migration direction in sources comments: SFDC → `SOURCE_ENTITY` over time. |

CRM **is** landed in this account under **`DS_SOURCE_PROD_SFDC.SFDC_SHARE`**, not only under `SOURCE_ENTITY`.

## RAW / SOURCE_PROD (from script)

- **RAW** schemas (excluding `INFORMATION_SCHEMA`): ADMIN, CENSUS, CHERRE, COSTAR, FIRST_STREET, MARKERR, NCES, PRETIUM_BTR, PUBLIC, REDFIN, REGRID, STANFORD, ZONDA (no dedicated BEA/CFPB/FBI/USPS/NOAA raw schemas in this probe list).
- **SOURCE_PROD** vendor-shaped schemas from probe: **FDIC** only (of FDIC, BEA, CFPB, FBI, USPS, NOAA).
