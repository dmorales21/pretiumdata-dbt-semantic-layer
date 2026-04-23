{{ config(materialized='ephemeral', tags=['reference', 'catalog', 'enum_ref']) }}

select distinct
    code as strategy_code
from {{ ref('catalog_enum_source') }}
where enum_table = 'investment_strategy'
  and trim(code) <> ''

