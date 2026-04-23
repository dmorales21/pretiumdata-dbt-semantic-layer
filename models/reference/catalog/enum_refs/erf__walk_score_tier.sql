{{ config(materialized='ephemeral', tags=['reference', 'catalog', 'enum_ref']) }}

select distinct
    code as walk_score_tier_code
from {{ ref('catalog_enum_source') }}
where enum_table = 'walk_score_tier'
  and trim(code) <> ''

