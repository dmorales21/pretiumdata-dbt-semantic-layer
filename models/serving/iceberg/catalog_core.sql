-- Intended **SERVING.ICEBERG.CATALOG_CORE** — union of curated REFERENCE.CATALOG slices for lake export.
-- Canonical members include **concept**, **dataset**, **concept_explanation** (Presley narrative),
-- **concept_offering_weight** (dense offering × concept routing), and other small registry tables.
-- Implement the physical `UNION ALL` in Snowflake (normalized `entity` + `payload` VARIANT, or one
-- Parquet per entity) inside the export Task.
{{ config(enabled=false) }}

select 'concept_explanation'::varchar as catalog_core_entity
from {{ ref('concept_explanation') }}
where false

union all

select 'concept_offering_weight'::varchar as catalog_core_entity
from {{ ref('concept_offering_weight') }}
where false

union all

select 'concept'::varchar as catalog_core_entity
from {{ ref('concept') }}
where false

union all

select 'dataset'::varchar as catalog_core_entity
from {{ ref('dataset') }}
where false
