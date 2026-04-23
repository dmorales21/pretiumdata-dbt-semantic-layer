{{ config(materialized='ephemeral', tags=['reference', 'catalog', 'enum_ref']) }}

select distinct
    code as estimate_type_code
from {{ ref('catalog_enum_source') }}
where enum_table = 'estimate_type'
  and trim(code) <> ''

