-- Dominant county per H3 R8 hex from BG→H3 polyfill weights (same bridge as ``fact_census_acs5_h3_r8_snapshot``).
-- County = first 5 digits of block-group GEOID (state + county). Tie-break: highest summed bridge weight.
-- Feeds ``int_acs5_h3_r8_county_demographics_rollups`` and corridor H3 facts rolled to county (e.g. transactions).
{{ config(
    materialized='table',
    alias='int_h3_r8_hex_dominant_county',
    tags=['transform', 'transform_dev', 'census', 'geo', 'intermediate'],
) }}

WITH h3_county_weights AS (
    SELECT
        TRIM(TO_VARCHAR(b.h3_r8_hex)) AS h3_r8_hex,
        LPAD(SUBSTRING(TRIM(TO_VARCHAR(b.bg_geoid)), 1, 5), 5, '0') AS county_fips,
        SUM(TRY_TO_DOUBLE(TO_VARCHAR(b.weight))) AS w_sum
    FROM {{ source('h3_polyfill_bridges', 'bridge_bg_h3_r8_polyfill') }} AS b
    WHERE b.h3_r8_hex IS NOT NULL
      AND b.bg_geoid IS NOT NULL
      AND LENGTH(TRIM(TO_VARCHAR(b.bg_geoid))) >= 5
    GROUP BY 1, 2
)

SELECT
    h3_r8_hex,
    county_fips
FROM h3_county_weights
QUALIFY ROW_NUMBER() OVER (
    PARTITION BY h3_r8_hex
    ORDER BY w_sum DESC NULLS LAST, county_fips
) = 1
