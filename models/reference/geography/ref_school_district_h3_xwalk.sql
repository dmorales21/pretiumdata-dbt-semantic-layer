{{
  config(
    alias = 'REF_SCHOOL_DISTRICT_H3_XWALK',
    materialized = 'table',
    tags = ['reference', 'geography', 'education', 'h3', 'crosswalk'],
    cluster_by = ['h3_8_hex', 'id_geo'],
  )
}}

-- REFERENCE.GEOGRAPHY.REF_SCHOOL_DISTRICT_H3_XWALK — Census school-district GEOID ↔ H3-6/8 (polygon fill).
-- Source: SOURCE_PROD.GEO.MAP_SCHOOLDISTRICT_H3 (see sources_source_prod_geo.yml).
select
    nullif(trim(id_geo), '') as id_geo,
    nullif(trim(name_geo), '') as name_geo,
    nullif(trim(h3_6_hex), '') as h3_6_hex,
    nullif(trim(h3_8_hex), '') as h3_8_hex,
    nullif(trim(source_vintage), '') as source_vintage
from {{ source('source_prod_geo', 'map_schooldistrict_h3') }}
where nullif(trim(id_geo), '') is not null
  and nullif(trim(h3_8_hex), '') is not null
