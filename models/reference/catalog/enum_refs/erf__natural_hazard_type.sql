{{ config(materialized='ephemeral', tags=['reference', 'catalog', 'enum_ref']) }}

select distinct
    code as hazard_type_code
from {{ ref('catalog_enum_source') }}
where enum_table = 'natural_hazard_type'
  and trim(code) <> ''

