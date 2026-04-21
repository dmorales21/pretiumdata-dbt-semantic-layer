{{
  config(
    alias = 'GEOGRAPHY_CODES',
    materialized = 'table',
    tags = ['reference', 'geography']
  )
}}

-- Physical target: REFERENCE.GEOGRAPHY.GEOGRAPHY_CODES — contract in models/reference/geography/schema.yml.
-- LEVEL lives on GEOGRAPHY_INDEX, not CHARACTERISTICS — join on normalized GEO_ID for dict + pivots.
-- If CHARACTERISTIC_* names differ, align IFF lists to DESCRIBE on your share.

with dict as (
    select
        upper(trim(source_snow_cybersyn_level)) as source_level_u,
        trim(geo_level_code) as geo_level_code
    from {{ ref('geo_level') }}
    where source_snow_cybersyn_level is not null
        and trim(source_snow_cybersyn_level) <> ''
),

raw as (
    select
        {{ normalize_cybersyn_geo_id('trim(c.geo_id)') }} as geo_id,
        trim(i.level) as source_level,
        lower(trim(c.relationship_type)) as relationship_type,
        trim(to_varchar(c.value)) as char_value
    from {{ source('global_government_cybersyn', 'geography_characteristics') }} as c
    left join {{ source('global_government_cybersyn', 'geography_index') }} as i
        on {{ normalize_cybersyn_geo_id('trim(c.geo_id)') }} = {{ normalize_cybersyn_geo_id('trim(i.geo_id)') }}
),

piv as (
    select
        r.geo_id,
        coalesce(d.geo_level_code, 'unmapped') as geo_level_code,
        max(iff(r.relationship_type in ('fips_code', 'fips', 'geoid'), r.char_value, null)) as fips_code,
        max(iff(r.relationship_type in ('fips_10_4_code', 'fips_10_4'), r.char_value, null)) as fips_10_4_code,
        max(iff(r.relationship_type = 'state_abbreviation', r.char_value, null)) as state_abbreviation
    from raw as r
    left join dict as d
        on d.source_level_u = upper(trim(r.source_level))
    group by r.geo_id, coalesce(d.geo_level_code, 'unmapped')
)

select
    geo_id as GEO_ID,
    geo_level_code as GEO_LEVEL_CODE,
    fips_code as FIPS_CODE,
    fips_10_4_code as FIPS_10_4_CODE,
    state_abbreviation as STATE_ABBREVIATION
from piv
