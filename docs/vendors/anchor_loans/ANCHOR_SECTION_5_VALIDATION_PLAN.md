# Anchor Tear Sheet — Section 5 (Maps & Charts) Validation Plan

**Purpose:** Validate all five Section 5 data sources and fix failing models. Only **5.4 School** works today; 5.1, 5.2, 5.3, 5.5 need validation and fixes.

---

## Summary: What Works vs What Fails

| Chart | Status | Root cause | Fix owner |
|-------|--------|------------|-----------|
| **5.1 Retailers map** | ❌ Fails | `cleaned_carto_major_retailers` is gated by `carto_retailers_enabled` (default false) and returns 0 rows; CARTO source often not populated | Enable CARTO or use alternative retailer source |
| **5.2 Zonda scatter** | ❌ Fails | View is stub when `anchor_zonda_comps_available` is false; or DS_TPANALYTICS.ZONDA not populated | Set var and load Zonda BTR comparables |
| **5.3 Starts vs closings** | 🔄 Zonda or JBRec | **Preferred:** Zonda (`--section5-zonda`). **Fallback:** JBRec MF units (`anchor_starts_closings_from_mf_fact: true`). Feature_market_spot deprecated. See ANCHOR_ZONDA_STARTS_CLOSINGS_WIRING.md. | — |
| **5.4 School choropleth** | ✅ Works | fact_place_plc_education_all_ts has ZIP-level data | — |
| **5.5 Crime choropleth** | ❌ Fails | fact_place_plc_safety_all_ts empty or no ZIP rows (Markerr/Cotality cleaned models not populated) | Load Markerr/Cotality crime data |

---

## 1) Validation steps (per viz)

Run these in Snowflake (or via dbt test) to confirm each delivery view returns data.

### 5.1 Retailers

```sql
-- Expect: rows per (deal_id, distance_band_mi) for deals with lat/lon. retailer_count can be 0 if no retailers.
SELECT deal_id, distance_band_mi, retailer_count, retailer_names
FROM EDW_PROD.DELIVERY.V_ANCHOR_DEAL_SCREENER_RETAILERS
ORDER BY deal_id, distance_band_mi
LIMIT 20;
```

**Pass:** ≥ 1 row per deal that has latitude/longitude in ANCHOR_LOANS.DEALS.  
**Fail:** 0 rows → DEALS has no lat/lon, or `fact_place_major_retailers` is empty (check `carto_retailers_enabled` and CARTO source).

**Upstream checks:**

```sql
SELECT COUNT(*) FROM TRANSFORM_PROD.FACT.FACT_PLACE_MAJOR_RETAILERS;  -- expect > 0 if retailers map should show non-zero counts
SELECT COUNT(*) FROM TRANSFORM_PROD.CLEANED.CLEANED_CARTO_MAJOR_RETAILERS;  -- same
```

### 5.2 Zonda scatter

```sql
SELECT cbsa_code, zip_code, unit_sqft, median_sale_price, builder_name
FROM EDW_PROD.DELIVERY.V_ANCHOR_ZONDA_COMPS
WHERE cbsa_code IS NOT NULL
LIMIT 20;
```

**Pass:** ≥ 10 rows for at least one CBSA (viz_validation min_rows for zonda_scatter).  
**Fail:** 0 rows → `anchor_zonda_comps_available` is false or DS_TPANALYTICS.ZONDA.ZONDA_BTR_COMPARABLES is empty.

**Upstream:** Set `--vars 'anchor_zonda_comps_available: true'` and ensure Zonda BTR comparables are loaded.

### 5.3 Starts vs closings

```sql
SELECT date_reference, cbsa_code, sfr_starts, sfr_closings
FROM EDW_PROD.DELIVERY.V_ANCHOR_STARTS_CLOSINGS_CBSA
ORDER BY date_reference
LIMIT 20;
```

**Pass:** ≥ 5 rows (viz_validation min_rows).  
**Fail:** 0 rows → view is stub; wire to feature_market_spot_cbsa or MF fact (see model fix below).

### 5.4 School choropleth

```sql
SELECT zip_code, cbsa_code, school_score, date_reference
FROM EDW_PROD.DELIVERY.V_ANCHOR_SCHOOL_SCORE_BY_ZIP
WHERE school_score IS NOT NULL
LIMIT 20;
```

**Pass:** ≥ 1 row with non-null school_score.  
**Fail:** All school_score null → fact_place_plc_education_all_ts has no ZIP data for that CBSA.

### 5.5 Crime choropleth

```sql
SELECT zip_code, cbsa_code, crime_score, date_reference
FROM EDW_PROD.DELIVERY.V_ANCHOR_CRIME_SCORE_BY_ZIP
WHERE crime_score IS NOT NULL
LIMIT 20;
```

**Pass:** ≥ 1 row with non-null crime_score.  
**Fail:** All crime_score null → fact_place_plc_safety_all_ts has no ZIP data (Markerr/Cotality not loaded or cleaned models empty).

**Upstream checks:**

```sql
SELECT geo_level_code, COUNT(*), MAX(date_reference)
FROM TRANSFORM_PROD.FACT.FACT_PLACE_PLC_SAFETY_ALL_TS
GROUP BY geo_level_code;
-- Expect ZIP rows with recent date_reference.
```

---

## 2) Model fixes (implemented or required)

### 5.1 Retailers

- **Model:** `models/edw_prod/delivery/views/v_anchor_deal_screener_retailers.sql` (no change; logic is correct).
- **Fix:** Populate retailers data:
  - Set `carto_retailers_enabled: true` in dbt_project or `--vars`.
  - Ensure source `carto.carto_place_layer` exists and has lat/lon (or geom).
  - Or add an alternative cleaned model that reads from another retailer source (e.g. Overture, seed) and point `fact_place_major_retailers` at it.

### 5.2 Zonda

- **Model:** `models/edw_prod/delivery/views/v_anchor_zonda_comps.sql` (no change; already conditional on var).
- **Fix:** Set `anchor_zonda_comps_available: true` and load DS_TPANALYTICS.ZONDA.ZONDA_BTR_COMPARABLES with columns CBSA, ID_ZIP, UNIT_SQFT, MEDIAN_SALE_PRICE, BUILDER_NAME.

### 5.3 Starts vs closings

- **Model:** `models/edw_prod/delivery/views/v_anchor_starts_closings_cbsa.sql`
- **Preferred:** Zonda — set `anchor_starts_closings_from_zonda: true`, load `DS_TPANALYTICS.ZONDA.ZONDA_STARTS_CLOSINGS` (or discovered table). Supports ZIP or CBSA grain. See `ANCHOR_ZONDA_STARTS_CLOSINGS_WIRING.md`.
- **Fallback:** JBRec MF — set `anchor_starts_closings_from_mf_fact: true`; uses MF_UNITS_STARTS (sfr_closings null).
- **Deprecated:** feature_market_spot_cbsa (do not use).

### 5.5 Crime

- **Model:** `models/edw_prod/delivery/views/v_anchor_crime_score_by_zip.sql` (no change; logic is correct).
- **Fix:** Populate safety fact:
  - Ensure `cleaned_markerr_crime_zip_long` and/or `cleaned_cotality_crime_school_tract_ts_tall` are run and have data.
  - Run `dbt run --select cleaned_markerr_crime_zip_long cleaned_cotality_crime_school_tract_ts_tall fact_place_plc_safety_all_ts` then rebuild delivery views.

---

## 3) dbt test / validation scripts

- Add generic tests or a custom test that:
  - For each delivery view, run a row-count check (e.g. expect ≥ 1 row when not in stub mode), or
  - Run SQL from Section 1 in a script and assert expected minima.
- See `scripts/anchor_tearsheet/verify/` for existing verification scripts; add `validate_section5_views.sql` that runs the five SELECTs above and documents expected row counts.

---

## 4) Citations (already in HTML)

The tear sheet HTML already includes a **Data citations** section at the bottom with vendor, metric definition, delivery view, and upstream table per chart. Keep that in sync with this plan.

---

## 5) Runbook order

1. Validate School (5.4) — confirm it still returns rows.
2. Fix Starts/closings (5.3) — wire view to feature or MF fact (see model change below).
3. Fix Crime (5.5) — ensure Markerr/Cotality and fact_place_plc_safety_all_ts have ZIP data; re-run.
4. Fix Retailers (5.1) — enable CARTO or alternative retailer source.
5. Fix Zonda (5.2) — enable var and load Zonda BTR comparables.

After each fix, re-run the tear sheet pipeline and confirm the corresponding viz shows data (not BLOCKED).

---

## 6) Vars reference (dbt)

| Var | Default | Effect |
|-----|---------|--------|
| `carto_retailers_enabled` | false | If true, cleaned_carto_major_retailers reads from CARTO; required for 5.1 retailers data. |
| `anchor_zonda_comps_available` | false | If true, v_anchor_zonda_comps reads from DS_TPANALYTICS.ZONDA; required for 5.2. |
| `zonda_starts_closings_available` | false | Gate source read. Set true only when DS_TPANALYTICS.ZONDA exists; else cleaned stubs (avoids schema-not-exist). |
| `anchor_starts_closings_from_zonda` | false | If true, delivery uses Zonda fact. Preferred. Supports ZIP or CBSA. Requires zonda_starts_closings_available for data. |
| `anchor_starts_closings_from_mf_fact` | true | Fallback: MF units starts from John Burns when Zonda not loaded. |

Run validation SQL: `scripts/anchor_tearsheet/verify/validate_section5_views.sql` in Snowflake after building delivery views.

---

## 7) Investigation: Why Data is Missing

**Run completed (2026-02-11):** All 5 Section 5 delivery views built successfully via:
```bash
DBT_DB=TRANSFORM_PROD DBT_SCHEMA=DEV dbt run --select v_anchor_school_score_by_zip v_anchor_crime_score_by_zip v_anchor_deal_screener_retailers v_anchor_zonda_comps v_anchor_starts_closings_cbsa --vars '{"anchor_starts_closings_from_mf_fact": true}'
```

Row counts depend on upstream data. Root causes for each missing viz:

### 5.1 Retailers — Why 0 rows

| Layer | Model / Source | Gate | Issue |
|-------|----------------|------|-------|
| Cleaned | `cleaned_carto_major_retailers` | `carto_retailers_enabled` (default: false) | Stub when false; returns 0 rows |
| Fact | `fact_place_major_retailers` | — | Reads from cleaned; inherits 0 rows |
| Source | `carto.carto_place_layer` | CARTO database access | Schema/catalog not yet wired; column vars (`carto_col_id`, `carto_col_lat`, etc.) need discovery |

**Fix:** Set `carto_retailers_enabled: true`, configure CARTO source (database/schema/columns), then run `dbt run --select cleaned_carto_major_retailers fact_place_major_retailers v_anchor_deal_screener_retailers`.

### 5.2 Zonda — Why 0 rows

| Layer | Model / Source | Gate | Issue |
|-------|----------------|------|-------|
| Delivery | `v_anchor_zonda_comps` | `anchor_zonda_comps_available` (default: false) | Stub when false; returns 0 rows |
| Source | `source_prod.zonda.zonda_btr_comparables` | — | Zonda BTR data not loaded or table empty |

**Fix:** Set `anchor_zonda_comps_available: true`, load `DS_TPANALYTICS.ZONDA.ZONDA_BTR_COMPARABLES` with columns CBSA, ID_ZIP, UNIT_SQFT, MEDIAN_SALE_PRICE, BUILDER_NAME, then run `dbt run --select v_anchor_zonda_comps`.

### 5.3 Starts/closings — Why 0 rows (or few)

| Layer | Model / Source | Gate | Issue |
|-------|----------------|------|-------|
| Zonda (preferred) | `cleaned_zonda_starts_closings` | `zonda_starts_closings_available` (default: false) | Set true only when DS_TPANALYTICS.ZONDA exists; else cleaned stubs. Also need `anchor_starts_closings_from_zonda: true` for delivery path. |
| JBRec (fallback) | `fact_housing_hou_multifamily_all_ts` (MF_UNITS_STARTS) | `anchor_starts_closings_from_mf_fact: true` | MF units only; sfr_closings null. Use `--no-section5-mf` if JBRec not loaded. |

**Fix:** Use Zonda: `./scripts/anchor/run_anchor_pipeline.sh --section5-zonda` after `DS_TPANALYTICS.ZONDA` is provisioned and loaded. See ANCHOR_ZONDA_STARTS_CLOSINGS_WIRING.md.

### 5.5 Crime — Why 0 rows with non-null crime_score

| Layer | Model / Source | Gate | Issue |
|-------|----------------|------|-------|
| Cleaned | `cleaned_markerr_crime_zip_long` | `place_ai_sources_available` (default: false) | Stub when false |
| Cleaned | `cleaned_cotality_crime_school_tract_ts_tall` | `place_cotality_available` (default: false) | Stub when false |
| Fact | `fact_place_plc_safety_all_ts` | — | Union of both; both stubs → 0 rows |
| Source (Markerr) | `source_prod.markerr.markerr_crime` | — | Column names: ZIPCODE, OVERALLCRIMEINDEX, etc. |
| Source (Cotality) | `ai_capabilities.cotality_crime_school_tract_ts_tall` | — | Tract-level; crosswalks to ZIP via h3_xwalk_6810_canon |

**Fix:** Set `place_ai_sources_available: true` (for Markerr) and/or `place_cotality_available: true` (for Cotality), ensure sources exist, then run:
```bash
dbt run --select cleaned_markerr_crime_zip_long cleaned_cotality_crime_school_tract_ts_tall fact_place_plc_safety_all_ts v_anchor_crime_score_by_zip --vars '{"place_ai_sources_available": true, "place_cotality_available": true}'
```

### Vars Quick Reference

| Var | Default | Effect |
|-----|--------|--------|
| `carto_retailers_enabled` | false | 5.1 retailers from CARTO |
| `anchor_zonda_comps_available` | false | 5.2 Zonda scatter |
| `anchor_starts_closings_from_zonda` | false | 5.3 from Zonda (preferred; ZIP or CBSA) |
| `anchor_starts_closings_from_mf_fact` | true | 5.3 fallback from JBRec MF units |
| `place_ai_sources_available` | false | 5.5 crime from Markerr |
| `place_cotality_available` | false | 5.5 crime from Cotality (tract→ZIP) |
