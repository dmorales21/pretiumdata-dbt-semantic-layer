{{ config(materialized='ephemeral', tags=['reference', 'catalog', 'enum_ref']) }}

select distinct
    code as vintage_code
from {{ ref('catalog_enum_source') }}
where enum_table = 'vintage'
  and trim(code) <> ''

