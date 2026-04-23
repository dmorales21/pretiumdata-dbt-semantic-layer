{{ config(materialized='ephemeral', tags=['reference', 'catalog', 'enum_ref']) }}

select distinct
    code as cap_rate_tier_code
from {{ ref('catalog_enum_source') }}
where enum_table = 'cap_rate_tier'
  and trim(code) <> ''

