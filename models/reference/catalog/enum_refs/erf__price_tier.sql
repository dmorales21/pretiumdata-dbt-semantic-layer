{{ config(materialized='ephemeral', tags=['reference', 'catalog', 'enum_ref']) }}

select distinct
    code as price_tier_code
from {{ ref('catalog_enum_source') }}
where enum_table = 'price_tier'
  and trim(code) <> ''

