{{ config(materialized='ephemeral', tags=['reference', 'catalog', 'enum_ref']) }}

select distinct
    code as vacancy_tier_code
from {{ ref('catalog_enum_source') }}
where enum_table = 'vacancy_tier'
  and trim(code) <> ''

