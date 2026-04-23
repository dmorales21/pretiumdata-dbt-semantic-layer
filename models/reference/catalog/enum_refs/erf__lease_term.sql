{{ config(materialized='ephemeral', tags=['reference', 'catalog', 'enum_ref']) }}

select distinct
    code as lease_term_code
from {{ ref('catalog_enum_source') }}
where enum_table = 'lease_term'
  and trim(code) <> ''

