{{ config(materialized='ephemeral', tags=['reference', 'catalog', 'enum_ref']) }}

select distinct
    code as amenity_tier_code
from {{ ref('catalog_enum_source') }}
where enum_table = 'amenity_tier'
  and trim(code) <> ''

