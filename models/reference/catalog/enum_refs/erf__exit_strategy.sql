{{ config(materialized='ephemeral', tags=['reference', 'catalog', 'enum_ref']) }}

select distinct
    code as exit_strategy_code
from {{ ref('catalog_enum_source') }}
where enum_table = 'exit_strategy'
  and trim(code) <> ''

