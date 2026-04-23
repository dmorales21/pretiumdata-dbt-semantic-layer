{{ config(materialized='ephemeral', tags=['reference', 'catalog', 'enum_ref']) }}

select distinct
    code as data_status_code
from {{ ref('catalog_enum_source') }}
where enum_table = 'data_status'
  and trim(code) <> ''

