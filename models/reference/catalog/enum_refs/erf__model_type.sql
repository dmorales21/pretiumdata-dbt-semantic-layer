{{ config(materialized='ephemeral', tags=['reference', 'catalog', 'enum_ref']) }}

select distinct
    code as model_type_code
from {{ ref('catalog_enum_source') }}
where enum_table = 'model_type'
  and trim(code) <> ''

