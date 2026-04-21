{{
  config(
    alias = 'GEOGRAPHY_RELATIONSHIPS',
    materialized = 'table',
    tags = ['reference', 'geography']
  )
}}

-- Physical target: REFERENCE.GEOGRAPHY.GEOGRAPHY_RELATIONSHIPS — contract in models/reference/geography/schema.yml.
-- RELATED_GEO_NAME: from GEOGRAPHY_INDEX when RELATED_GEO_ID + RELATED_SOURCE_LEVEL resolve (Cybersyn may omit name on edge).

with dict as (
    select
        upper(trim(source_snow_cybersyn_level)) as source_level_u,
        trim(geo_level_code) as geo_level_code
    from {{ ref('geo_level') }}
    where source_snow_cybersyn_level is not null
        and trim(source_snow_cybersyn_level) <> ''
),

idx as (
    select
        {{ normalize_cybersyn_geo_id('trim(i.geo_id)') }} as geo_id,
        trim(i.geo_name) as geo_name,
        trim(i.level) as source_level
    from {{ source('global_government_cybersyn', 'geography_index') }} as i
),

edges as (
    select
        {{ normalize_cybersyn_geo_id('trim(gr.geo_id)') }} as geo_id,
        trim(gr.geo_name) as geo_name,
        trim(gr.level) as source_level,
        coalesce(d1.geo_level_code, 'unmapped') as geo_level_code,
        {{ normalize_cybersyn_geo_id('trim(gr.related_geo_id)') }} as related_geo_id,
        trim(rel_idx.geo_name) as related_geo_name,
        trim(gr.related_level) as related_source_level,
        coalesce(d2.geo_level_code, 'unmapped') as related_geo_level_code,
        trim(gr.relationship_type) as relationship_type
    from {{ source('global_government_cybersyn', 'geography_relationships') }} as gr
    left join dict as d1
        on d1.source_level_u = upper(trim(gr.level))
    left join dict as d2
        on d2.source_level_u = upper(trim(gr.related_level))
    left join idx as rel_idx
        on rel_idx.geo_id = {{ normalize_cybersyn_geo_id('trim(gr.related_geo_id)') }}
        and upper(trim(rel_idx.source_level)) = upper(trim(gr.related_level))
)

select
    geo_id as GEO_ID,
    geo_name as GEO_NAME,
    source_level as SOURCE_LEVEL,
    geo_level_code as GEO_LEVEL_CODE,
    related_geo_id as RELATED_GEO_ID,
    related_geo_name as RELATED_GEO_NAME,
    related_source_level as RELATED_SOURCE_LEVEL,
    related_geo_level_code as RELATED_GEO_LEVEL_CODE,
    relationship_type as RELATIONSHIP_TYPE
from edges
