{{ config(materialized='ephemeral', tags=['reference', 'catalog', 'enum_ref']) }}

select distinct
    code as geo_status_code
from {{ ref('catalog_enum_source') }}
where enum_table = 'geography_status'
  and trim(code) <> ''

