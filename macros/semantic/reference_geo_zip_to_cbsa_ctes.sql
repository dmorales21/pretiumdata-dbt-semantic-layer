{% macro reference_geo_zip_to_cbsa_ctes() %}
{#-
  Reusable CTEs: HUD postal → primary county → primary CBSA for ``reference_geography_year()``.
  Same logic as ``zillow_research_fact_enriched`` so ApartmentIQ / Yardi Matrix ZIP paths align with Zillow facts.
-#}
county_cbsa_primary AS (
    SELECT
        county_fips,
        cbsa_id
    FROM (
        SELECT
            LPAD(TRIM(TO_VARCHAR(x.COUNTY_FIPS)), 5, '0')     AS county_fips,
            LPAD(TRIM(TO_VARCHAR(x.CBSA_CODE)), 5, '0')      AS cbsa_id,
            ROW_NUMBER() OVER (
                PARTITION BY LPAD(TRIM(TO_VARCHAR(x.COUNTY_FIPS)), 5, '0')
                ORDER BY
                    CASE WHEN x.CBSA_CODE IS NULL THEN 1 ELSE 0 END,
                    TRIM(TO_VARCHAR(x.CBSA_NAME)) ASC NULLS LAST,
                    LPAD(TRIM(TO_VARCHAR(x.CBSA_CODE)), 5, '0') ASC NULLS LAST
            ) AS rn
        FROM {{ source('reference_geography', 'county_cbsa_xwalk') }} AS x
        WHERE x.YEAR = {{ reference_geography_year() }}
          AND x.COUNTY_FIPS IS NOT NULL
    ) AS z
    WHERE z.rn = 1
),

zip_spine AS (
    SELECT
        id_zip,
        county_fips
    FROM (
        SELECT
            LPAD(TRIM(pc.ID_ZIP::VARCHAR), 5, '0') AS id_zip,
            LPAD(TRIM(pc.ID_COUNTY::VARCHAR), 5, '0') AS county_fips,
            ROW_NUMBER() OVER (
                PARTITION BY LPAD(TRIM(pc.ID_ZIP::VARCHAR), 5, '0')
                ORDER BY
                    pc.YEAR DESC NULLS LAST,
                    pc.QUARTER DESC NULLS LAST,
                    COALESCE(pc.TOT_RATIO, pc.RES_RATIO, 0) DESC NULLS LAST,
                    LPAD(TRIM(pc.ID_COUNTY::VARCHAR), 5, '0') ASC
            ) AS rn
        FROM {{ source('reference_geography', 'postal_county_xwalk') }} AS pc
        WHERE pc.ID_ZIP IS NOT NULL
          AND pc.ID_COUNTY IS NOT NULL
    ) AS zr
    WHERE zr.rn = 1
),

zip_enriched AS (
    SELECT
        zs.id_zip,
        zs.county_fips,
        ccp.cbsa_id
    FROM zip_spine AS zs
    LEFT JOIN county_cbsa_primary AS ccp
        ON zs.county_fips = ccp.county_fips
)
{% endmacro %}
