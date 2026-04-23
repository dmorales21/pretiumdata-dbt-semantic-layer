{{ config(materialized='ephemeral', tags=['reference', 'catalog', 'enum_ref']) }}

select distinct
    code as segment_code
from {{ ref('catalog_enum_source') }}
where enum_table = 'population_segment'
  and trim(code) <> ''

