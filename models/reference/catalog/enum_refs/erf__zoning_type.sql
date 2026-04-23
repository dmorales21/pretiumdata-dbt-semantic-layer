{{ config(materialized='ephemeral', tags=['reference', 'catalog', 'enum_ref']) }}

select distinct
    code as zoning_type_code
from {{ ref('catalog_enum_source') }}
where enum_table = 'zoning_type'
  and trim(code) <> ''

