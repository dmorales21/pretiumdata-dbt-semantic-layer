# Parcl Property Search V2 and REFERENCE.CATALOG alignment

**Purpose:** Keep Pretium warehouse dimensions comparable to [Property Search V2](https://api.parcllabs.com/v2/property_search) request bodies (`parcl_property_ids`, `parcl_ids`, `geo_coordinates`, `property_filters`, `event_filters`) so property search, market panels, and comping share one vocabulary.

## Canonical bridge (dbt seed)

| Seed | Snowflake after `dbt seed` |
|------|----------------------------|
| `dbt/seeds/reference/catalog/parcl_property_search_dimension_bridge.csv` | `REFERENCE.CATALOG.PARCL_PROPERTY_SEARCH_DIMENSION_BRIDGE` |

**Join pattern (property type):**

```sql
FROM source_or_table p
LEFT JOIN reference.catalog.parcl_property_search_dimension_bridge b
  ON b.vendor_dataset = 'PARCLLABS_PROPERTY_SEARCH_V2'
 AND b.external_group = 'property_types'
 AND upper(trim(p.property_type)) = upper(trim(b.external_code))
```

Use `b.reference_product_type_code` with `reference.catalog.product_type` for underwriting pillars and cross-vendor consensus. `OTHER` intentionally has a null canonical product type.

## Product type seed

Parcl enum **CONDO** maps to **`product_type_code = condo`** (`PT_010` in `product_type.csv`). **SINGLE_FAMILY**, **TOWNHOUSE** map to `sf_scattered` and `townhome` respectively.

## dbt models

| Model | Role |
|-------|------|
| `cleaned_parcllabs_rent_listings` | Passes through `parcl_property_id` and `parcl_id` when the source supplies them for listing-level joins. |
| `dev_parcllabs_progress_rents_catalog_dims` | `PROGRESS_RENTS` + catalog bridge for Progress / Property Search V2 style rows. **Disabled by default** (`transform_dev_enable_parcllabs_progress_rents_catalog_dims` in `dbt_project.yml`) until `SOURCE_PROD.PARCLLABS.PROGRESS_RENTS` exists. Enable: `--vars '{"transform_dev_enable_parcllabs_progress_rents_catalog_dims": true}'`. |

## API vs RENT_LISTINGS column names

Property Search V2 distinguishes **market** `parcl_ids` from **property** `parcl_property_ids`. The legacy `RENT_LISTINGS` table may name columns differently; confirm with `DESCRIBE TABLE SOURCE_PROD.PARCLLABS.RENT_LISTINGS` before equating `PARCL_ID` to either API field.

## Validation

Run `scripts/sql/validation/validate_rent_avm_vendor_spine.sql` with `snowsql -c pretium` for object presence and coarse row counts.
