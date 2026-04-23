{{ config(materialized='ephemeral', tags=['reference', 'catalog', 'enum_ref']) }}

select distinct
    code as hoa_type_code
from {{ ref('catalog_enum_source') }}
where enum_table = 'hoa_type'
  and trim(code) <> ''

