{{ config(materialized='ephemeral', tags=['reference', 'catalog', 'enum_ref']) }}

select distinct
    code as gate_code
from {{ ref('catalog_enum_source') }}
where enum_table = 'promotion_gate'
  and trim(code) <> ''

