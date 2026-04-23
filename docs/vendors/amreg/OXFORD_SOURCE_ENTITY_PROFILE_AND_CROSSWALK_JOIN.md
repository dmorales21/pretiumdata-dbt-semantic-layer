# Oxford Economics — `SOURCE_ENTITY.PRETIUM` profile, crosswalk join, and fact conventions

**As-of:** 2026-04-19 (Snowflake `pretium` profile)  
**Purpose:** Lock physical shape, **exact CBSA join** to `TRANSFORM_PROD.REF.OXFORD_CBSA_CROSSWALK`, **`TRANSFORM.DEV.REF_OXFORD_METRO_CBSA`**, and **`metric_id` / `frequency` / `date_reference`** rules for `FACT_OXFORD_AMREG_QUARTERLY` and `FACT_OXFORD_WDMARCO_QUARTERLY`.

---

## 1. `SOURCE_ENTITY.PRETIUM.AMREG` — DESCRIBE + profile

### 1.1 Shape: **long (tall)**

One row per **location × indicator × year × period** (plus metadata). Not a wide pivot.

### 1.2 Columns (`DESCRIBE TABLE SOURCE_ENTITY.PRETIUM.AMREG`)

| Column | Type | Role |
|--------|------|------|
| `Ingest_Date` | TIMESTAMP_NTZ | Load metadata |
| `Filename` | VARCHAR | Source file |
| `Location` | VARCHAR | Display name |
| `Indicator` | VARCHAR | Human-readable series name |
| `Region_Type` | VARCHAR | `MSA`, `MSAD`, `State/Province`, `Country` |
| `Sector` | VARCHAR | Sector / grouping |
| `Units`, `Scale`, `Measurement` | VARCHAR | Units and measure semantics |
| `Source`, `Seasonally_adjusted`, `Base_year_*`, `Historical_end_*` | VARCHAR | Vendor metadata |
| `Date_of_last_update`, `Source_details`, `Additional_source_details` | VARCHAR | Provenance |
| **`Location_code`** | VARCHAR | **Oxford geography key** (join to crosswalk) |
| **`Indicator_code`** | VARCHAR | **Stable series code** (preferred for `metric_id`) |
| **`Period`** | VARCHAR | `Annual`, `Qtr 1` … `Qtr 4` |
| `Unique_id`, `Series_id` | VARCHAR | Vendor identifiers |
| **`Data`** | FLOAT | Numeric value |
| **`Year`** | NUMBER(38,0) | Calendar / forecast year |

### 1.3 Profile (counts and ranges)

| Metric | Value |
|--------|------|
| **Row count** | **97,799,498** |
| **Year** | **1980–2050** (forecasts included) |
| **`Period` values** | `Annual` (~19.56M rows each bucket); `Qtr 1`–`Qtr 4` (~19.56M each) — **five-way split** |
| **`Region_Type`** | `MSA` ~81.49M; `State/Province` ~10.10M; `MSAD` ~5.96M; `Country` ~0.24M |
| **MSA slice** (`Region_Type = 'MSA'`) | **657** distinct `Indicator`, **672** distinct `Indicator_code`, **302** distinct `Location_code` |

### 1.4 Date fields

There is **no** explicit `DATE` column. Build **`date_reference`** from **`Year`** + **`Period`** (see §5).

---

## 2. `SOURCE_ENTITY.PRETIUM.WDMARCO` — DESCRIBE + profile

### 2.1 Shape: **long (tall)**

Same column family as AMREG, **without** `Region_Type` / `Sector` on the table (national macro feed).

### 2.2 Columns (`DESCRIBE TABLE SOURCE_ENTITY.PRETIUM.WDMARCO`)

Same as AMREG **except** omitted: `Region_Type`, `Sector`.

### 2.3 Profile

| Metric | Value |
|--------|------|
| **Row count** | **2,383,830** |
| **Year** | **1980–2060** |
| **`Location` / `Location_code`** | **United States / USA** only (single geography) |
| **`Period`** | Balanced across `Annual`, `Qtr 1`–`Qtr 4` (~476,766 rows each) |
| **Distinct series** | **956** `Indicator`, **991** `Indicator_code` |

### 2.4 Geo level

**National (USA)** for all rows in this account snapshot. Facts should use **`geo_level_code = 'NATIONAL'`**, **`geo_id = 'USA'`** (or agreed national sentinel), **`ID_CBSA = NULL`**, unless a future feed adds subnational rows.

---

## 3. `TRANSFORM_PROD.REF.OXFORD_CBSA_CROSSWALK` — DESCRIBE

| Column | Type | Null? |
|--------|------|-------|
| **`LOCATION_CODE_OXFORD`** | VARCHAR(50) | N |
| `LOCATION_NAME_OXFORD` | VARCHAR(500) | N |
| **`REGION_TYPE_OXFORD`** | VARCHAR(50) | N |
| `ID_CBSA` | VARCHAR(10) | Y |
| `NAME_CBSA` | VARCHAR(500) | Y |
| `MATCH_METHOD` | VARCHAR(50) | Y |
| `MATCH_CONFIDENCE` | VARCHAR(20) | Y |
| `MATCH_NOTES` | VARCHAR(1000) | Y |
| `CREATED_AT`, `UPDATED_AT` | TIMESTAMP_NTZ | Y |

**Row count:** **302**. **`REGION_TYPE_OXFORD`:** all **`MSA`**.

---

## 4. Exact join: AMREG → Pretium CBSA (crosswalk)

### 4.1 Recommended join (MSA rows that map to Pretium CBSA)

```sql
FROM SOURCE_ENTITY.PRETIUM.AMREG a
INNER JOIN TRANSFORM_PROD.REF.OXFORD_CBSA_CROSSWALK xw
  ON TRIM(a."Location_code") = xw.LOCATION_CODE_OXFORD
 AND a."Region_Type" = xw.REGION_TYPE_OXFORD
```

**Rationale:** The crosswalk is **MSA-only** (`REGION_TYPE_OXFORD = 'MSA'` for all 302 rows). Matching **`Region_Type`** avoids collisions if Oxford reuses location codes across region types.

**After join, Pretium CBSA key:** `xw.ID_CBSA` (and `xw.NAME_CBSA` for labels).

### 4.2 Coverage check (this account)

| `AMREG.Region_Type` | Distinct `Location_code` | Distinct crosswalk-matched codes |
|---------------------|--------------------------|----------------------------------|
| **MSA** | 302 | **302** |
| **MSAD** | 23 | **0** |
| `State/Province` | 38 | 0 |
| `Country` | 1 | 0 |

**Implication:** **`MSAD`** (and state/country rows) **do not** map through this crosswalk. For CBSA-level facts, **filter `Region_Type = 'MSA'`** *or* supply a separate **MSAD → MSA/CBSA** rule before joining.

### 4.3 Legacy documentation alignment

Existing notes such as `DATA_FRESHNESS_AND_AMREG_COMPLETE.md` use **`a."Location_code" = xw.LOCATION_CODE_OXFORD`**. That remains valid for **MSA-only** extracts; the **stricter** predicate above adds **`Region_Type` = `REGION_TYPE_OXFORD`** for correctness.

---

## 5. Locked conventions: `metric_id`, `frequency`, `date_reference`

### 5.1 `date_reference` — **quarter / year start (calendar)**

Align with `dbt/models/transform_prod/cleaned/amreg_cbsa_economics_materialized.sql`:

| `Period` | `date_reference` |
|----------|------------------|
| `Annual` | **January 1** of `Year` (`DATE_FROM_PARTS(Year, 1, 1)`) |
| `Qtr 1` | **January 1** of `Year` |
| `Qtr 2` | **April 1** of `Year` |
| `Qtr 3` | **July 1** of `Year` |
| `Qtr 4` | **October 1** of `Year` |

This is **quarter start**, not quarter end. Document in fact/column comments so no consumer assumes quarter-end reporting dates.

### 5.2 `frequency`

| `Period` | `frequency` |
|----------|-------------|
| `Annual` | **`ANNUAL`** |
| `Qtr 1`–`Qtr 4` | **`QUARTERLY`** |

### 5.3 `metric_id` (stable, registry-friendly)

**Primary rule:** Use Oxford **`Indicator_code`** (already short and stable), uppercased, with a vendor prefix:

- **AMREG:** `metric_id = 'AMREG_' || UPPER(NULLIF(TRIM("Indicator_code"), ''))`  
  - Example: `XEMPE6221` → **`AMREG_XEMPE6221`**
- **WDMARCO:** `metric_id = 'WDMARCO_' || UPPER(NULLIF(TRIM("Indicator_code"), ''))`  
  - Example: `FC071USC` → **`WDMARCO_FC071USC`**

**Secondary / display:** Keep `Indicator` (long name) in a **`metric_name`** or **`meta_description`** column on a bridge table or in `DIM_METRIC` description — do **not** use raw `Indicator` text as the primary `metric_id` (special characters, length, drift).

**Compatibility note:** Existing models sometimes use semantic ids like `AMREG_PERSONAL_INCOME_REAL`. Those should be mapped via **`DIM_METRIC`** (alias / deprecated_id) to the **`AMREG_<INDICATOR_CODE>`** key, or via an explicit seed bridge — **do not** silently duplicate two ids for the same physical series.

### 5.4 `unit`

Map from **`Units`**, **`Scale`**, and **`Measurement`** (and Oxford dictionary `data/reference/oxford_economics_metric_definitions.csv`) into the fact’s **`unit`** column; if unknown, use a governed default (e.g. `UNKNOWN`) rather than mislabeling.

---

## 6. `TRANSFORM.DEV.REF_OXFORD_METRO_CBSA` (materialized)

**Definition:** One-time / repeatable build:

```sql
CREATE OR REPLACE TABLE TRANSFORM.DEV.REF_OXFORD_METRO_CBSA AS
SELECT
    LOCATION_CODE_OXFORD AS oxford_location_code,
    LOCATION_NAME_OXFORD AS oxford_location_name,
    REGION_TYPE_OXFORD AS oxford_region_type,
    ID_CBSA               AS id_cbsa,
    NAME_CBSA             AS name_cbsa,
    MATCH_METHOD          AS match_method,
    MATCH_CONFIDENCE      AS match_confidence,
    MATCH_NOTES           AS match_notes,
    CREATED_AT            AS source_created_at,
    UPDATED_AT            AS source_updated_at
FROM TRANSFORM_PROD.REF.OXFORD_CBSA_CROSSWALK;
```

**Status (2026-04-18):** Table created; **302** rows.

**Join from DEV ref to AMREG (same logic as prod, DEV column names):**

```sql
FROM SOURCE_ENTITY.PRETIUM.AMREG a
INNER JOIN TRANSFORM.DEV.REF_OXFORD_METRO_CBSA xw
  ON TRIM(a."Location_code") = xw.OXFORD_LOCATION_CODE
 AND a."Region_Type" = xw.OXFORD_REGION_TYPE
```

**Git anchor:** `scripts/sql/source_entity/materialize_ref_oxford_metro_cbsa_dev.sql`

---

## 7. Next build steps (facts)

**Migration register (pretiumdata-dbt-semantic-layer):** `docs/migration/MIGRATION_TASKS.md` — task IDs **`T-DEV-REF-OXFORD-METRO-CBSA`**, **`T-DEV-FACT-OXFORD-AMREG-QUARTERLY`**, **`T-DEV-FACT-OXFORD-WDMARCO-QUARTERLY`**; checklist **`MIGRATION_TASKS_OXFORD_SOURCE_ENTITY_DEV.md`**.

1. Staging models: `source_entity.pretium` → typed selects + quoted identifiers.  
2. `FACT_OXFORD_AMREG_QUARTERLY`: join **§4.1**, apply **§5**, filter **`Region_Type = 'MSA'`** for CBSA outputs until MSAD is solved.  
3. `FACT_OXFORD_WDMARCO_QUARTERLY`: **§2.4** national grain + **§5**.  
4. Register metrics in **`DIM_METRIC`** / `register_oxford_economics_metrics.sql` using **`AMREG_*` / `WDMARCO_*`** codes from §5.3.

---

## 8. Oxford execution order (this repository)

Use this sequence when wiring **Oxford Economics** objects in Snowflake and dbt; keep **pretiumdata-dbt-semantic-layer** migration tasks in sync when **`TRANSFORM.DEV`** targets exist.

**Side audit (Stanford SEDA, same inventory pass):** `STANFORD_SEDA_CROSSWALK_PARQUET` duplicate check on **`leaid` + `year`** showed **119,776** bad rows; hold school-district grain facts until reconciled or waived in governance.

1. **Metro → CBSA reference (done path):** Run `snowsql -c pretium -f scripts/sql/source_entity/materialize_ref_oxford_metro_cbsa_dev.sql` from the **repository root** (loads `TRANSFORM.DEV.REF_OXFORD_METRO_CBSA` from `TRANSFORM_PROD.REF.OXFORD_CBSA_CROSSWALK`). Doc status: **302 rows** as of **2026-04-18**.
2. **AMREG facts (existing transform_prod stack):** `amreg_cbsa_economics_materialized` → `fact_amreg_cbsa_economics` implements the **CBSA × quarterly** unpivot pattern. Align metric_ids and join keys with **§4–§5** before renaming or adding parallel **`FACT_OXFORD_AMREG_QUARTERLY`** in **`TRANSFORM.DEV`**.
3. **WDMARCO:** Add source + cleaned + fact when extracts land; use **`WDMARCO_` + normalized `Indicator_code`** per **§5.3**.
4. **Catalog registration:** Extend `scripts/sql/admin/catalog/register_oxford_economics_metrics.sql` (and seeds under `dbt/seeds/oxford_economics_metrics.csv` / metric definitions) so **`ADMIN.CATALOG.DIM_METRIC`** matches the chosen ids.
5. **Semantic-layer checklist:** When Snowflake objects match **`T-DEV-REF-OXFORD-METRO-CBSA`**, **`T-DEV-FACT-OXFORD-AMREG-QUARTERLY`**, and **`T-DEV-FACT-OXFORD-WDMARCO-QUARTERLY`**, mark those rows **migrated** in **`MIGRATION_TASKS.md`** and append **`MIGRATION_LOG.md`** in **pretiumdata-dbt-semantic-layer**.
