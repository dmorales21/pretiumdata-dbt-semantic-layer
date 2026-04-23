{{ config(materialized='ephemeral', tags=['reference', 'catalog', 'enum_ref']) }}

select distinct
    code as occupancy_status_code
from {{ ref('catalog_enum_source') }}
where enum_table = 'occupancy_status'
  and trim(code) <> ''

