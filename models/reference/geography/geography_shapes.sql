{{
  config(
    alias = 'GEOGRAPHY_SHAPES',
    materialized = 'table',
    tags = ['reference', 'geography']
  )
}}

-- Physical target: REFERENCE.GEOGRAPHY.GEOGRAPHY_SHAPES — contract in models/reference/geography/schema.yml.

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
        max(iff(r.relationship_type in ('coordinates_wkt', 'wkt', 'geometry_wkt'), r.char_value, null)) as coordinates_wkt,
        max(iff(r.relationship_type in ('coordinates_geojson', 'geojson'), r.char_value, null)) as coordinates_geojson
    from raw as r
    left join dict as d
        on d.source_level_u = upper(trim(r.source_level))
    group by r.geo_id, coalesce(d.geo_level_code, 'unmapped')
),

with_geo as (
    select
        geo_id,
        geo_level_code,
        coordinates_wkt,
        coordinates_geojson,
        try_to_geography(coordinates_wkt) as shape_geography
    from piv
),

flags as (
    select
        geo_id,
        geo_level_code,
        coordinates_wkt,
        coordinates_geojson,
        shape_geography,
        cast(null as varchar(64)) as shape_type,
        -- Snowflake GEOGRAPHY: ST_ISEMPTY is not supported; treat parsed non-null as valid (tighten with ST_AREA if needed).
        iff(shape_geography is not null, true, false) as is_valid_shape
    from with_geo
)

select
    geo_id as GEO_ID,
    geo_level_code as GEO_LEVEL_CODE,
    coordinates_wkt as COORDINATES_WKT,
    coordinates_geojson as COORDINATES_GEOJSON,
    shape_geography as SHAPE_GEOGRAPHY,
    shape_type as SHAPE_TYPE,
    is_valid_shape as IS_VALID_SHAPE
from flags
