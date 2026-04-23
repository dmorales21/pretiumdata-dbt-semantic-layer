{{ config(materialized='ephemeral', tags=['reference', 'catalog', 'enum_ref']) }}

select distinct
    code as construction_status_code
from {{ ref('catalog_enum_source') }}
where enum_table = 'construction_status'
  and trim(code) <> ''

