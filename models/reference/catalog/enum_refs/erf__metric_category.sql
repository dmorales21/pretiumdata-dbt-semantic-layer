{{ config(materialized='ephemeral', tags=['reference', 'catalog', 'enum_ref']) }}

select distinct
    code as category_code
from {{ ref('catalog_enum_source') }}
where enum_table = 'metric_category'
  and trim(code) <> ''

