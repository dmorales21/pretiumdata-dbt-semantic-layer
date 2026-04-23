{{ config(materialized='ephemeral', tags=['reference', 'catalog', 'enum_ref']) }}

select distinct
    code as phase_code
from {{ ref('catalog_enum_source') }}
where enum_table = 'market_cycle_phase'
  and trim(code) <> ''

