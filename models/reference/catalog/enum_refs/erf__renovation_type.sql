{{ config(materialized='ephemeral', tags=['reference', 'catalog', 'enum_ref']) }}

select distinct
    code as renovation_type_code
from {{ ref('catalog_enum_source') }}
where enum_table = 'renovation_type'
  and trim(code) <> ''

