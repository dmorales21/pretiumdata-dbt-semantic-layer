{{ config(materialized='ephemeral', tags=['reference', 'catalog', 'enum_ref']) }}

select distinct
    code as sector_code
from {{ ref('catalog_enum_source') }}
where enum_table = 'employment_sector'
  and trim(code) <> ''

