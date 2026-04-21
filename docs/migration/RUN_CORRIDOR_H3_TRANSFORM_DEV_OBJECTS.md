# Runbook — corridor H3 / LODES objects on `TRANSFORM.DEV`

Builds the **LODES + employment-center** chain in **`TRANSFORM.DEV`** with **no** `source()` to **`ANALYTICS.FACTS`**.

## Prerequisites (Snowflake)

- Role / warehouse that can read **`TRANSFORM.LODES`** (`OD_BG`, `OD_H3_R8` via existing read-through), the **H3 polyfill bridges** (**`REFERENCE.GEOGRAPHY.BLOCKGROUP_H3_R8_POLYFILL`**, `BRIDGE_ZIP_H3_R8_POLYFILL`), and write **`TRANSFORM.DEV`**. Build the BG bridge with pretium-ai-dbt **`scripts/sql/reference/geography/blockgroup_h3_r8_polyfill.sql`**.
- By default, bridges resolve to **`REFERENCE.GEOGRAPHY`** via dbt source **`h3_polyfill_bridges`** (`dbt_project.yml` vars **`h3_polyfill_bridge_database`** / **`h3_polyfill_bridge_schema`**).

## Troubleshooting — `Object 'REFERENCE.GEOGRAPHY.BLOCKGROUP_H3_R8_POLYFILL' does not exist or not authorized`

Many roles still have the compat mirrors under **`ANALYTICS.REFERENCE`** (same identifiers). That is **not** `analytics.facts`. Point the source at them:

**One-off CLI:**

```bash
dbt run --selector corridor_h3_transform_dev \
  --vars '{"h3_polyfill_bridge_database": "ANALYTICS", "h3_polyfill_bridge_schema": "REFERENCE", "h3_polyfill_bg_bridge_identifier": "BRIDGE_BG_H3_R8_POLYFILL"}'
```

Omit **`h3_polyfill_bg_bridge_identifier`** when **ANALYTICS.REFERENCE** already has **`BLOCKGROUP_H3_R8_POLYFILL`** (preferred mirror of the canonical table).

**Or** set the same keys under `vars:` in `dbt_project.yml` (or your profile `vars`) for persistent local dev.

## Commands (run yourself)

From the **inner** project directory:

`pretiumdata-dbt-semantic-layer/pretiumdata-dbt-semantic-layer/`

1. **Parse / compile** (optional sanity check):

   ```bash
   dbt parse
   ```

2. **Run the corridor H3 selector** (includes **`fact_lodes_od_h3_r8_annual`** via `selectors.yml` union):

   ```bash
   dbt run --selector corridor_h3_transform_dev
   ```

   Alternative (CLI graph operator — also pulls any untagged parents of the tagged set):

   ```bash
   dbt run --select +tag:corridor_h3_transform_dev
   ```

## Objects created (catalog: `dataset.csv` DS_086–DS_089)

| Snowflake object | dbt model |
|------------------|-----------|
| `TRANSFORM.DEV.FACT_LODES_OD_WORKPLACE_HEX_ANNUAL` | `fact_lodes_od_workplace_hex_annual` |
| `TRANSFORM.DEV.REF_CORRIDOR_EMPLOYMENT_CENTERS` | `ref_corridor_employment_centers` |
| `TRANSFORM.DEV.FACT_LODES_H3R8_WORKPLACE_GRAVITY` | `fact_lodes_h3r8_workplace_gravity` |
| `TRANSFORM.DEV.FACT_LODES_NEAREST_CENTER_H3_R8_ANNUAL` | `fact_lodes_nearest_center_h3_r8_annual` |

Upstream read-through (not tagged with `corridor_h3_transform_dev`, but required):

- `TRANSFORM.DEV.FACT_LODES_OD_H3_R8_ANNUAL` ← `models/transform/dev/lodes/fact_lodes_od_h3_r8_annual.sql`
- **`fact_lodes_nearest_center_h3_r8_annual`** reads the CBSA hex spine from **`source('h3_polyfill_bridges','bridge_bg_h3_r8_polyfill')`** (physical **`REFERENCE.GEOGRAPHY.BLOCKGROUP_H3_R8_POLYFILL`** by default).
- Full chain registration: **`registry/lineage/corridor_lodes_h3_r8_lineage.yml`**
