# dbt plan — tall `CONCEPT_*` observations (TRANSFORM.DEV)

**Status:** execution plan (no physical tall table shipped in this change set unless a model is added alongside this doc).

## Goals

1. **Read** vendor-native **`FACT_*`** (and, during migration, wide **`CONCEPT_*`**) as staging.
2. **Emit** one row per measure with explicit **`metric_code`**, **`dataset_code`**, **`vendor_code`**, geo keys, period columns, **`value`**.
3. **Materialize** under **TRANSFORM.DEV** per [`../rules/SCHEMA_RULES.md`](../rules/SCHEMA_RULES.md) and [`../rules/ARCHITECTURE_RULES.md`](../rules/ARCHITECTURE_RULES.md).
4. **Register** every emitted **`metric_code`** in built **`metric.csv`** (FACT/CONCEPT core + closure) before merging to main.

## Transform pattern

- **Per-vendor CTEs** that select FACT columns already aligned to catalog codes (preferred), or
- **`UNPIVOT`** / **`UNION ALL`** from long-form FACT (`METRIC_ID`, `METRIC_VALUE`) with a static mapping seed: slot column name → `metric_code`.

Do **not** rely on wide slot names (`rent_current`) as the long-term key — maintain **one documented mapping table** (SQL CTE, seed, or macro) from slot + vendor branch → `metric_code`.

## `metric.table_path`

For each tall output object (single table or per-concept), add or update **`REFERENCE.CATALOG.METRIC`** rows so **`table_path`** points at the **tall table** (or document multi-table) and **`snowflake_column`** is **`VALUE`** when the measure lives in a value column.

## Testing

- Relationship tests: tall model → `ref('metric')` on `metric_code`, `ref('dataset')` on `dataset_code` where columns exist.
- Snowflake / CI: [`../../scripts/sql/validation/catalog_tall_metric_code_coverage.sql`](../../scripts/sql/validation/catalog_tall_metric_code_coverage.sql) once the tall table exists.

## Related

- Row contract: [`../reference/CONCEPT_OBSERVATION_TALL_ROW_CONTRACT.md`](../reference/CONCEPT_OBSERVATION_TALL_ROW_CONTRACT.md)  
- Wide → tall map: [`CONCEPT_METRIC_WIDE_TO_TALL_MIGRATION_MAP.md`](./CONCEPT_METRIC_WIDE_TO_TALL_MIGRATION_MAP.md)
