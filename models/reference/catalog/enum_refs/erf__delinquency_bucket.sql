{{ config(materialized='ephemeral', tags=['reference', 'catalog', 'enum_ref']) }}

select distinct
    code as bucket_code
from {{ ref('catalog_enum_source') }}
where enum_table = 'delinquency_bucket'
  and trim(code) <> ''

