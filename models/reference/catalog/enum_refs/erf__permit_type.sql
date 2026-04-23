{{ config(materialized='ephemeral', tags=['reference', 'catalog', 'enum_ref']) }}

select distinct
    code as permit_type_code
from {{ ref('catalog_enum_source') }}
where enum_table = 'permit_type'
  and trim(code) <> ''

