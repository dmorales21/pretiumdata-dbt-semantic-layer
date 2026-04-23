{{ config(materialized='ephemeral', tags=['reference', 'catalog', 'enum_ref']) }}

select distinct
    code as income_band_code
from {{ ref('catalog_enum_source') }}
where enum_table = 'income_band'
  and trim(code) <> ''

