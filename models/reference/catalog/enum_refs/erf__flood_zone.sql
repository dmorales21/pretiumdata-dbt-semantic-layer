{{ config(materialized='ephemeral', tags=['reference', 'catalog', 'enum_ref']) }}

select distinct
    code as flood_zone_code
from {{ ref('catalog_enum_source') }}
where enum_table = 'flood_zone'
  and trim(code) <> ''

