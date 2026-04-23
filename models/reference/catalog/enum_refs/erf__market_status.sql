{{ config(materialized='ephemeral', tags=['reference', 'catalog', 'enum_ref']) }}

select distinct
    code as market_status_code
from {{ ref('catalog_enum_source') }}
where enum_table = 'market_status'
  and trim(code) <> ''

