# Anchor Deal Memo — Getting Real Data

The deal memo PDF is built from **EDW_PROD.DELIVERY** views. Those views join deal geography (ZIP, CBSA) to fact tables. If the memo shows **ZIP: —** and **CBSA: —** and all metrics as **—** or **0**, the deal has **no geography** in the source.

## Where the data comes from

| What you see in the memo | Source |
|--------------------------|--------|
| Deal ID, ZIP, CBSA, loan amount, status | **SOURCE_ENTITY.ANCHOR_LOANS.DEALS** (one row per deal) |
| Portfolio (closed deals, UPB, Progress homes 10 mi) | DEALS + **TRANSFORM_PROD.REF.UNIFIED_PORTFOLIO** |
| Location, Demographics, Housing (scores, population, income, etc.) | JOINs on **deal ZIP** and **deal CBSA** to fact tables (housing_*, household_*, fact_place_*, etc.) |
| Retailers 1/3/5 mi | Deal **LATITUDE, LONGITUDE** + **TRANSFORM_PROD.FACT.FACT_PLACE_MAJOR_RETAILERS** |
| Zonda comps, starts/closings, school/crime by ZIP | Views filtered by **deal CBSA** |

So: **ZIP_CODE**, **ID_CBSA**, and (for retailers) **LATITUDE** / **LONGITUDE** in **DEALS** must be populated for the memo to have real numbers.

## Diagnose

From repo root:

```bash
python scripts/anchor/build_deal_memo_pdf.py LIBERTY_HILLS --diagnose
```

This prints the **screener row** and the **source DEALS row** from Snowflake. Check:

- **SOURCE_ENTITY.ANCHOR_LOANS.DEALS**: `ZIP_CODE`, `ID_CBSA`, `LATITUDE`, `LONGITUDE`
- If they are NULL or empty, the memo will be empty until you fix the source.

## How to fix (get real data)

Your deal may already have **LATITUDE** and **LONGITUDE** (e.g. from H3) but **ZIP_CODE** and **ID_CBSA** still NULL. The screener joins on ZIP and CBSA, so those two must be set for metrics to appear. Use one of the options below.

1. **Geocoding / reverse-geocode**  
   Run your normal process that fills geography (e.g. **PROCESS_NEW_DEALS()**). If the deal has lat/lon but no ZIP/CBSA, use a reverse-geocode step (or a Snowflake spatial join to a ZIP/CBSA boundary table if you have one) to set **ZIP_CODE** and **ID_CBSA** in DEALS.

2. **Manual update**  
   If you know the correct ZIP and CBSA for LIBERTY_HILLS, update the deal in Snowflake:
   ```sql
   UPDATE SOURCE_ENTITY.ANCHOR_LOANS.DEALS
   SET ZIP_CODE = '78664', ID_CBSA = '12420', LATITUDE = <lat>, LONGITUDE = <lon>
   WHERE DEAL_ID = 'LIBERTY_HILLS';
   ```
   (Use real values for your deal; 78664 / 12420 are examples.)

3. **Refresh views**  
   After DEALS is updated, refresh the screener so the view sees the new geography:
   ```bash
   dbt run --select tag:anchor_screener --vars '{anchor_household_labor_from_cps: false}'
   ```
   Or run the full Liberty Hill pipeline: `./scripts/anchor/run_liberty_hill_full_pipeline.sh`

4. **Rebuild the memo**  
   ```bash
   python scripts/anchor/build_deal_memo_pdf.py LIBERTY_HILLS
   ```

## Summary

| Symptom | Cause | Action |
|--------|--------|--------|
| ZIP: —, CBSA: —, all metrics — or 0 | DEALS has no ZIP_CODE / ID_CBSA for this deal | Populate geography in SOURCE_ENTITY.ANCHOR_LOANS.DEALS (geocoding or manual update), then refresh views and rebuild memo |
| Retailers always 0 | DEALS has no LATITUDE / LONGITUDE (or fact_place_major_retailers is empty) | Set lat/lon in DEALS; ensure retailers fact is populated |
| Zonda / starts-closings / school / crime empty | View is stub, or no data for this CBSA | Enable data sources (vars), or expect empty until sources are wired |
