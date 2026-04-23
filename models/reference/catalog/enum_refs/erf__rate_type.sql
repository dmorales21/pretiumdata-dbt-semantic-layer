{{ config(materialized='ephemeral', tags=['reference', 'catalog', 'enum_ref']) }}

select distinct
    code as rate_type_code
from {{ ref('catalog_enum_source') }}
where enum_table = 'rate_type'
  and trim(code) <> ''

