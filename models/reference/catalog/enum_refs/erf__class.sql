{{ config(materialized='ephemeral', tags=['reference', 'catalog', 'enum_ref']) }}

select distinct
    code as class_code
from {{ ref('catalog_enum_source') }}
where enum_table = 'class'
  and trim(code) <> ''

