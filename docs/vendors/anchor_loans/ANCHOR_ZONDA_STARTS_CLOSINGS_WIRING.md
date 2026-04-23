# Anchor Section 5.3: Zonda Starts & Closings Wiring

**Purpose:** Wire Section 5.3 (starts vs closings line chart) to Zonda data instead of feature_market_spot (deprecated) or JBRec MF fallback. Zonda is the preferred source; output is ZIP grain (delivery aggregates to CBSA).

---

## Overview

| Component | Role |
|-----------|------|
| **Sources** | **Closings:** `zonda_deed_closings` (from tpanalytics_share.zonda_deeds). **Starts:** `zonda_btr_pipeline` (from tpanalytics_share.zonda_btr_comprehensive). |
| **Cleaned** | `cleaned_zonda_starts_closings` — aggregates deed closings by month/ZIP and BTR pipeline by construction_start_date month/ZIP; full outer join → date_reference, geo_id (ZIP), sfr_starts, sfr_closings |
| **Delivery** | `v_anchor_starts_closings_cbsa` — aggregates ZIP→CBSA when needed, outputs for line chart |

---

## 1. Discover Zonda Schema in Snowflake

Run discovery to confirm table and column names. **Only run after `DS_TPANALYTICS.ZONDA` exists** (otherwise queries will fail):

```sql
-- List Zonda tables
SELECT table_name FROM DS_TPANALYTICS.information_schema.tables
WHERE table_schema = 'ZONDA' ORDER BY 1;

-- Describe the starts/closings table (name may vary: ZONDA_STARTS_CLOSINGS, NEW_HOME_STARTS, etc.)
DESCRIBE TABLE DS_TPANALYTICS.zonda.<actual_table_name>;
```

**No single-table source.** Cleaned is built from `zonda_deed_closings` and `zonda_btr_pipeline` (both from `DS_SOURCE_PROD_TPANALYTICS.TPANALYTICS_SHARE`). Ensure those cleaned models are built (they gate on source existence).

---

## 2. Expected Columns (adjust via vars)

The cleaned model expects a table with date, geography, starts, closings. Common Zonda naming:

| Logical | Possible column names | Var override |
|---------|----------------------|--------------|
| Date | date_reference, PERIOD_END, REPORT_DATE, YEAR, MONTH | `zonda_sc_col_date` |
| Geography | geo_id, CBSA, ID_CBSA, ID_ZIP, ZIP, METRO | `zonda_sc_col_geo` |
| Geo level | geo_level, GEO_LEVEL, (infer from column) | `zonda_sc_col_geo_level` |
| Starts | starts, STARTS, NEW_HOME_STARTS | `zonda_sc_col_starts` |
| Closings | closings, CLOSINGS, SALES | `zonda_sc_col_closings` |

If the table uses different names, add to `dbt_project.yml` or pass `--vars`:

```yaml
vars:
  zonda_sc_col_date: PERIOD_END
  zonda_sc_col_geo: CBSA
  zonda_sc_col_geo_level: null   # or column name if present
  zonda_sc_col_starts: NEW_HOME_STARTS
  zonda_sc_col_closings: CLOSINGS
```

If the table name differs, add `identifier` in `sources.yml` for `zonda_starts_closings`.

---

## 3. Enable Zonda Path

**Var for delivery path:**
- **`anchor_starts_closings_from_zonda`** — When true, delivery uses Zonda fact (preferred). When false, uses JBRec MF fallback.

```yaml
# dbt_project.yml (or --vars)
vars:
  anchor_starts_closings_from_zonda: true
  anchor_starts_closings_from_mf_fact: false   # disable JBRec fallback
```

Or run with:

```bash
dbt run --select cleaned_zonda_starts_closings fact_zonda_starts_closings_all_ts v_anchor_starts_closings_cbsa \
  --vars '{"anchor_starts_closings_from_zonda": true, "anchor_starts_closings_from_mf_fact": false}'
```

---

## 4. Geography Support

- **CBSA-level:** If source has CBSA/Metro column, set `geo_level_code` to `CBSA` (or pass via `zonda_sc_col_geo_level`). Rows used directly.
- **ZIP-level:** If source has ZIP, set `geo_level_code` to `ZIP`. Delivery view aggregates to CBSA via `cbsa_zip_weights`.
- **H3:** Not yet supported. Zonda typically provides CBSA or ZIP; if H3 exists, add a crosswalk in cleaned or a separate branch.

---

## 5. Validation

```sql
SELECT date_reference, cbsa_code, sfr_starts, sfr_closings
FROM EDW_PROD.DELIVERY.V_ANCHOR_STARTS_CLOSINGS_CBSA
ORDER BY date_reference
LIMIT 20;
```

Pass: ≥ 5 rows (viz_validation min_rows for starts_closings).
