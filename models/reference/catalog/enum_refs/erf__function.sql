{{ config(materialized='ephemeral', tags=['reference', 'catalog', 'enum_ref']) }}

select distinct
    code as function_code
from {{ ref('catalog_enum_source') }}
where enum_table = 'function'
  and trim(code) <> ''

