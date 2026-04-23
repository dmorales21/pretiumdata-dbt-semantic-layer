{{ config(materialized='ephemeral', tags=['reference', 'catalog', 'enum_ref']) }}

select distinct
    code as condition_code
from {{ ref('catalog_enum_source') }}
where enum_table = 'property_condition'
  and trim(code) <> ''

