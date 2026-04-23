{{ config(materialized='ephemeral', tags=['reference', 'catalog', 'enum_ref']) }}

select distinct
    code as transit_score_tier_code
from {{ ref('catalog_enum_source') }}
where enum_table = 'transit_score_tier'
  and trim(code) <> ''

