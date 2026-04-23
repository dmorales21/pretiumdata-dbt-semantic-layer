{{ config(materialized='ephemeral', tags=['reference', 'catalog', 'enum_ref']) }}

select distinct
    code as risk_rating_code
from {{ ref('catalog_enum_source') }}
where enum_table = 'risk_rating'
  and trim(code) <> ''

