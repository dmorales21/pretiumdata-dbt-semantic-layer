{{ config(materialized='ephemeral', tags=['reference', 'catalog', 'enum_ref']) }}

select distinct
    code as deal_status_code
from {{ ref('catalog_enum_source') }}
where enum_table = 'deal_status'
  and trim(code) <> ''

