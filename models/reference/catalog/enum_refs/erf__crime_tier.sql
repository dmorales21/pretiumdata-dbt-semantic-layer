{{ config(materialized='ephemeral', tags=['reference', 'catalog', 'enum_ref']) }}

select distinct
    code as crime_tier_code
from {{ ref('catalog_enum_source') }}
where enum_table = 'crime_tier'
  and trim(code) <> ''

