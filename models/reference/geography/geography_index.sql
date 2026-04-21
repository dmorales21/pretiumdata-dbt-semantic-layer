{{
  config(
    alias = 'GEOGRAPHY_INDEX',
    materialized = 'table',
    tags = ['reference', 'geography']
  )
}}

-- Physical target: REFERENCE.GEOGRAPHY.GEOGRAPHY_INDEX (this repo owns column contract — models/reference/geography/schema.yml).
-- Extend with real ISO_* when Cybersyn DESCRIBE shows those columns; keep NULLs until then.

with dict as (
    select
        upper(trim(source_snow_cybersyn_level)) as source_level_u,
        trim(geo_level_code) as geo_level_code
    from {{ ref('geo_level') }}
    where source_snow_cybersyn_level is not null
        and trim(source_snow_cybersyn_level) <> ''
),

src as (
    select
        trim(src.geo_id) as geo_id_raw,
        trim(src.geo_name) as geo_name,
        trim(src.level) as source_level
    from {{ source('global_government_cybersyn', 'geography_index') }} as src
),

joined as (
    select
        {{ normalize_cybersyn_geo_id('s.geo_id_raw') }} as geo_id,
        s.geo_name,
        s.source_level,
        -- Cybersyn ships LEVEL strings not yet listed on ref('geo_level').source_snow_cybersyn_level; keep
        -- GEO_LEVEL_CODE non-null for tests and joins — extend geo_level.csv rather than leaving NULL.
        coalesce(d.geo_level_code, 'unmapped') as geo_level_code,
        cast(null as varchar(256)) as iso_name,
        cast(null as varchar(8)) as iso_alpha2,
        cast(null as varchar(8)) as iso_alpha3,
        cast(null as varchar(16)) as iso_numeric_code,
        cast(null as varchar(16)) as iso_3166_2_code
    from src as s
    left join dict as d
        on d.source_level_u = upper(trim(s.source_level))
),

deduped as (
    select
        *,
        row_number() over (partition by geo_id order by geo_name) as rn
    from joined
)

select
    geo_id as GEO_ID,
    geo_name as GEO_NAME,
    source_level as SOURCE_LEVEL,
    geo_level_code as GEO_LEVEL_CODE,
    iso_name as ISO_NAME,
    iso_alpha2 as ISO_ALPHA2,
    iso_alpha3 as ISO_ALPHA3,
    iso_numeric_code as ISO_NUMERIC_CODE,
    iso_3166_2_code as ISO_3166_2_CODE
from deduped
where rn = 1
