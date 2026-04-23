{{ config(materialized='ephemeral', tags=['reference', 'catalog', 'enum_ref']) }}

select distinct
    code as units_code
from {{ ref('catalog_enum_source') }}
where enum_table = 'units_in_structure'
  and trim(code) <> ''

