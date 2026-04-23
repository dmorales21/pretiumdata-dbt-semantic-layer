{{ config(materialized='ephemeral', tags=['reference', 'catalog', 'enum_ref']) }}

select distinct
    code as portfolio_size_tier_code
from {{ ref('catalog_enum_source') }}
where enum_table = 'portfolio_size_tier'
  and trim(code) <> ''

