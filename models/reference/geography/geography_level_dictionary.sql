{{
  config(
    alias = 'GEOGRAPHY_LEVEL_DICTIONARY',
    materialized = 'table',
    tags = ['reference', 'geography']
  )
}}

-- Cybersyn LEVEL → warehouse geo_level_code. Source rows: seeds/reference/catalog/geo_level.csv (source_snow_cybersyn_level).
-- One row per non-null Cybersyn LEVEL string; canonical vocabulary includes additional catalog-only grains on geo_level.

select
    'GLOBAL_GOVERNMENT' as source_system,
    trim(source_snow_cybersyn_level) as source_level,
    trim(geo_level_code) as canonical_geo_level_code,
    trim(geo_level_label) as canonical_geo_level_name,
    trim(geography_class) as geography_class,
    trim(supported_in_reference) as supported_in_reference,
    trim(shape_expected) as shape_expected,
    trim(code_system) as code_system,
    trim(geo_level_notes) as notes
from {{ ref('geo_level') }}
where source_snow_cybersyn_level is not null
  and trim(source_snow_cybersyn_level) <> ''
