{{ config(materialized='ephemeral', tags=['reference', 'catalog', 'enum_ref']) }}

select distinct
    code as noi_tier_code
from {{ ref('catalog_enum_source') }}
where enum_table = 'noi_tier'
  and trim(code) <> ''

