{{ config(materialized='ephemeral', tags=['reference', 'catalog', 'enum_ref']) }}

select distinct
    code as tenancy_code
from {{ ref('catalog_enum_source') }}
where enum_table = 'tenancy'
  and trim(code) <> ''

