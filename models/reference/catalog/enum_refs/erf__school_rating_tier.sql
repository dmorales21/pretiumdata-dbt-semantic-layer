{{ config(materialized='ephemeral', tags=['reference', 'catalog', 'enum_ref']) }}

select distinct
    code as school_rating_tier_code
from {{ ref('catalog_enum_source') }}
where enum_table = 'school_rating_tier'
  and trim(code) <> ''

