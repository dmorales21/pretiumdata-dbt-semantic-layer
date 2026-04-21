{{
  config(
    alias = 'GEOGRAPHY_LATEST',
    materialized = 'table',
    tags = ['reference', 'geography']
  )
}}

-- Physical target: REFERENCE.GEOGRAPHY.GEOGRAPHY_LATEST — contract in models/reference/geography/schema.yml.
-- Current snapshot: index + codes + shapes + rel_agg parents. Cybersyn share *_pit tables stay in SOURCE_SNOW for true as-of history.

with rel_agg as (
    select
        gr.geo_id,
        max(
            iff(
                lower(gr.related_geo_level_code) = 'state',
                lpad(to_varchar(rc.fips_code), 2, '0'),
                null
            )
        ) as state_fips,
        max(
            iff(
                lower(gr.related_geo_level_code) = 'county',
                rc.fips_code,
                null
            )
        ) as county_fips,
        max(
            iff(
                lower(gr.related_geo_level_code) = 'cbsa',
                rc.fips_code,
                null
            )
        ) as cbsa_id,
        max(
            iff(
                lower(gr.related_geo_level_code) = 'cbsa',
                ridx.geo_name,
                null
            )
        ) as cbsa_name
    from {{ ref('geography_relationships') }} as gr
    left join {{ ref('geography_codes') }} as rc
        on gr.related_geo_id = rc.geo_id
        and lower(gr.related_geo_level_code) = lower(rc.geo_level_code)
    left join {{ ref('geography_index') }} as ridx
        on gr.related_geo_id = ridx.geo_id
        and lower(gr.related_geo_level_code) = lower(ridx.geo_level_code)
    group by gr.geo_id
)

select
    idx.geo_id as GEO_ID,
    idx.geo_name as GEO_NAME,
    idx.geo_level_code as GEO_LEVEL_CODE,
    idx.source_level as SOURCE_LEVEL,
    rel.state_fips as STATE_FIPS,
    rel.county_fips as COUNTY_FIPS,
    rel.cbsa_id as CBSA_ID,
    rel.cbsa_name as CBSA_NAME,
    cod.state_abbreviation as STATE_ABBREVIATION,
    shp.shape_geography as SHAPE_GEOGRAPHY,
    true as IS_CURRENT
from {{ ref('geography_index') }} as idx
left join {{ ref('geography_codes') }} as cod
    on idx.geo_id = cod.geo_id
    and idx.geo_level_code = cod.geo_level_code
left join {{ ref('geography_shapes') }} as shp
    on idx.geo_id = shp.geo_id
    and idx.geo_level_code = shp.geo_level_code
left join rel_agg as rel
    on idx.geo_id = rel.geo_id
