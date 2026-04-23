{{ config(materialized='ephemeral', tags=['reference', 'catalog', 'enum_ref']) }}

select distinct
    code as loan_type_code
from {{ ref('catalog_enum_source') }}
where enum_table = 'loan_type'
  and trim(code) <> ''

