{{ config(materialized='ephemeral', tags=['reference', 'catalog', 'enum_ref']) }}

select distinct
    code as hold_period_code
from {{ ref('catalog_enum_source') }}
where enum_table = 'hold_period'
  and trim(code) <> ''

