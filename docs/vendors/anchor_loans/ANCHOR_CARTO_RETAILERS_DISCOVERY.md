# CARTO → Major Retailers: Discovery and Wiring (all in-repo)

**Purpose:** Populate `FACT_PLACE_MAJOR_RETAILERS` (and thus `V_ANCHOR_DEAL_SCREENER_RETAILERS` / `V_ANCHOR_DEAL_SCREENER_RETAILERS_DETAIL`) from CARTO place data.  
**All logic is in-repo:** macros, vars, and the cleaned model. No manual SQL in Snowflake required.

---

## 1. Discovery (in-repo macro)

From the project root:

```bash
dbt run-operation describe_carto_place_columns
```

This runs the macro in **`macros/anchor/carto_retailers.sql`**, which queries `information_schema.columns` for the CARTO place table and logs column names and types. Requires read access to the CARTO database/schema.

Vars used by the macro (optional overrides in `dbt_project.yml`):

- `carto_database` (default `carto`)
- `carto_schema` (default `public`)
- `carto_place_table` (default `carto_place_layer`)

---

## 2. Column mapping (vars)

The cleaned model **`cleaned_carto_major_retailers`** uses the macro **`anchor_carto_retailer_select('p')`**, which reads vars for each output column. Set these in `dbt_project.yml` (under `vars:`) to match your CARTO table:

| Var | Default | Description |
|-----|--------|-------------|
| `carto_retailers_enabled` | `false` | Set `true` to read from CARTO; otherwise 0-row stub. |
| `carto_col_id` | `id` | Column for retailer_id |
| `carto_col_name` | `name` | Column for retailer_name |
| `carto_col_lat` | `latitude` | Column for latitude (ignored if using geom) |
| `carto_col_lon` | `longitude` | Column for longitude (ignored if using geom) |
| `carto_col_geom` | `geom` | Geometry column; use with `carto_use_geom_for_xy` |
| `carto_use_geom_for_xy` | `false` | If `true`, lat/lon come from ST_Y/ST_X(ST_CENTROID(geom)) |
| `carto_col_address` | `address` | Optional |
| `carto_col_zip_code` | `zip_code` | Optional |
| `carto_col_cbsa_code` | `cbsa_code` | Optional |
| `carto_col_category` | `category` | Optional |

---

## 3. Enable and run

1. Set `carto_retailers_enabled: true` and any column overrides in `dbt_project.yml`.
2. Run:

   ```bash
   dbt run --select cleaned_carto_major_retailers
   dbt run --select fact_place_major_retailers
   dbt run --select +v_anchor_deal_screener_retailers+
   ```

3. Verify: `FACT_PLACE_MAJOR_RETAILERS` has rows; retailer views show distance bands.

---

## References

- **Macros:** `macros/anchor/carto_retailers.sql` (`anchor_carto_retailer_select`, `describe_carto_place_columns`)
- **Cleaned:** `models/transform_prod/cleaned/cleaned_carto_major_retailers.sql`
- **Fact:** `models/transform_prod/fact/fact_place_major_retailers.sql`
- **Memo:** `docs/vendors/anchor_loans/ANCHOR_SCREENER_WHAT_IS_MISSING.md` (sections 2.4, 5.1)
