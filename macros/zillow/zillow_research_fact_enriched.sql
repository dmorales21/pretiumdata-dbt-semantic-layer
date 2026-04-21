{% macro zillow_research_fact_enriched(raw_source_table, dataset_slug) %}
{#-
  Zillow research VARIANT unpivot + Census-aligned keys for TRANSFORM.DEV.FACT_*.

  Migration rules (docs/migration/CURSOR_MIGRATION_PROMPT.md):
  - RAW_* via source('zillow', raw_source_table) on SOURCE_PROD.ZILLOW
  - Exclude geo_level_code city, neighborhood
  - metro / msa → catalog geo_level_code cbsa (vendor RegionID unchanged in geo_id)
  - ZIP: **REFERENCE.GEOGRAPHY.POSTAL_COUNTY_XWALK** (HUD USPS ZIP→county, latest YEAR/QUARTER per ZIP)
    + primary county row from COUNTY_CBSA_XWALK by `reference_geography_year()` (ZCTA `ZIP_COUNTY_XWALK` not required)
  - County: seed ref_zillow_county_to_fips (TRANSFORM.DEV)
  - Metro/msa: **TRANSFORM.DEV.REF_ZILLOW_METRO_TO_CBSA** (`source('transform_dev_vendor_ref','ref_zillow_metro_to_cbsa')`) — Alex copy; populate before build (see migration SQL).
  - State: ZILLOW_ALL + static US state name → FIPS map

  **Metro xwalk column profile** (`var('zillow_metro_to_cbsa_xwalk_profile', 'legacy_jon')`):
  - `legacy_jon`: physical cols **zillow_6_digit** + **census_5_digit** (Jon `TRANSFORM.REF` `SELECT *` CTAS per `create_ref_zillow_metro_to_cbsa.sql`).
  - `alex_metro_ref`: physical cols **zillow_region_id** + **cbsa_id** (bridge-style; matches `DESCRIBE` when DEV table was built from analytics bridge, not raw Jon names). If compile errors on `census_5_digit`, set this var or run `reshape_ref_zillow_metro_to_cbsa_to_macro_columns.sql`.
-#}
{% set _zmt = var('zillow_metro_to_cbsa_xwalk_profile', 'legacy_jon') %}
{% if _zmt == 'alex_metro_ref' %}
    {% set _z6 = 'zillow_region_id' %}
    {% set _cb = 'cbsa_id' %}
{% else %}
    {% set _z6 = 'zillow_6_digit' %}
    {% set _cb = 'census_5_digit' %}
{% endif %}
WITH long_pre AS (
    {{ unpivot_zillow_research_long(raw_source_table, dataset_slug) }}
),

long_f AS (
    SELECT *
    FROM long_pre
    WHERE geo_level_code NOT IN ('city', 'neighborhood')
),

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
),

state_name_fips AS (
    SELECT UPPER(TRIM(state_name)) AS state_name_upper, state_fips
    FROM (VALUES
        ('ALABAMA', '01'), ('ALASKA', '02'), ('ARIZONA', '04'), ('ARKANSAS', '05'),
        ('CALIFORNIA', '06'), ('COLORADO', '08'), ('CONNECTICUT', '09'), ('DELAWARE', '10'),
        ('DISTRICT OF COLUMBIA', '11'), ('FLORIDA', '12'), ('GEORGIA', '13'), ('HAWAII', '15'),
        ('IDAHO', '16'), ('ILLINOIS', '17'), ('INDIANA', '18'), ('IOWA', '19'),
        ('KANSAS', '20'), ('KENTUCKY', '21'), ('LOUISIANA', '22'), ('MAINE', '23'),
        ('MARYLAND', '24'), ('MASSACHUSETTS', '25'), ('MICHIGAN', '26'), ('MINNESOTA', '27'),
        ('MISSISSIPPI', '28'), ('MISSOURI', '29'), ('MONTANA', '30'), ('NEBRASKA', '31'),
        ('NEVADA', '32'), ('NEW HAMPSHIRE', '33'), ('NEW JERSEY', '34'), ('NEW MEXICO', '35'),
        ('NEW YORK', '36'), ('NORTH CAROLINA', '37'), ('NORTH DAKOTA', '38'), ('OHIO', '39'),
        ('OKLAHOMA', '40'), ('OREGON', '41'), ('PENNSYLVANIA', '42'), ('RHODE ISLAND', '44'),
        ('SOUTH CAROLINA', '45'), ('SOUTH DAKOTA', '46'), ('TENNESSEE', '47'), ('TEXAS', '48'),
        ('UTAH', '49'), ('VERMONT', '50'), ('VIRGINIA', '51'), ('WASHINGTON', '53'),
        ('WEST VIRGINIA', '54'), ('WISCONSIN', '55'), ('WYOMING', '56')
    ) AS t(state_name, state_fips)
),

z_states AS (
    SELECT DISTINCT
        CAST(a.region_id AS VARCHAR(32))    AS zillow_state_region_id,
        TRIM(a.region_name)                 AS zillow_state_name
    FROM {{ source('zillow', 'zillow_all') }} AS a
    WHERE LOWER(TRIM(a.region_type)) = 'state'
      AND a.region_id IS NOT NULL
      AND TRIM(a.region_name) <> ''
)

SELECT
    long_f.geo_id,
    CASE
        WHEN long_f.geo_level_code IN ('metro', 'msa') THEN 'cbsa'
        ELSE long_f.geo_level_code
    END                                                                               AS geo_level_code,
    long_f.date_reference,
    long_f.metric_id,
    long_f.metric_value,
    long_f.vendor_name,
    long_f.dataset_slug,
    long_f.region_name,
    long_f.size_rank,
    long_f.region_type,
    long_f.state_name,
    long_f.source_file_name,
    long_f.batch_snapshot_date,
    long_f.loaded_at,
    COALESCE(
        LPAD(NULLIF(TRIM(m_cb.{{ _cb }}::VARCHAR), ''), 5, '0'),
        LPAD(NULLIF(TRIM(cn.cbsa_code::VARCHAR), ''), 5, '0'),
        ze.cbsa_id
    )                                                                                 AS cbsa_id,
    COALESCE(
        LPAD(NULLIF(TRIM(cn.fips_5digit::VARCHAR), ''), 5, '0'),
        ze.county_fips
    )                                                                                 AS county_fips,
    COALESCE(
        s_map.state_fips,
        LPAD(NULLIF(TRIM(cn.state_fips::VARCHAR), ''), 2, '0'),
        LEFT(COALESCE(LPAD(NULLIF(TRIM(cn.fips_5digit::VARCHAR), ''), 5, '0'), ze.county_fips), 2)
    )                                                                                 AS state_fips,
    CAST(NULL AS VARCHAR(16))                                                         AS census_place_fips,
    COALESCE(
        LPAD(NULLIF(TRIM(m_cb.{{ _cb }}::VARCHAR), ''), 5, '0'),
        LPAD(NULLIF(TRIM(cn.fips_5digit::VARCHAR), ''), 5, '0'),
        ze.county_fips,
        s_map.state_fips
    ) IS NOT NULL                                                                      AS has_census_geo,
    CASE
        WHEN long_f.geo_level_code IN ('metro', 'msa')
            AND m_cb.{{ _cb }} IS NOT NULL
            THEN 'zillow_to_census_cbsa_mapping'
        WHEN long_f.geo_level_code = 'county'
            AND cn.fips_5digit IS NOT NULL
            THEN 'ref_zillow_county_to_fips'
        WHEN long_f.geo_level_code = 'state'
            AND s_map.state_fips IS NOT NULL
            THEN 'zillow_all_state_name_map'
        WHEN long_f.geo_level_code = 'zip'
            AND ze.id_zip IS NOT NULL
            THEN 'hud_postal_county_xwalk_plus_county_cbsa_xwalk'
        ELSE NULL
    END                                                                               AS census_geo_source,
    CURRENT_TIMESTAMP()                                                               AS dbt_updated_at
FROM long_f
LEFT JOIN {{ source('transform_dev_vendor_ref', 'ref_zillow_metro_to_cbsa') }} AS m_cb
    ON long_f.geo_level_code IN ('metro', 'msa')
   AND LPAD(TRIM(long_f.geo_id), 6, '0') = LPAD(TRIM(m_cb.{{ _z6 }}::VARCHAR), 6, '0')
   AND m_cb.{{ _z6 }} IS NOT NULL
   AND m_cb.{{ _cb }} IS NOT NULL
LEFT JOIN {{ ref('ref_zillow_county_to_fips') }} AS cn
    ON long_f.geo_level_code = 'county'
   AND TRIM(long_f.geo_id) = TRIM(TO_VARCHAR(cn.county_region_id))
LEFT JOIN z_states AS zs
    ON long_f.geo_level_code = 'state'
   AND TRIM(long_f.geo_id) = zs.zillow_state_region_id
LEFT JOIN state_name_fips AS s_map
    ON zs.zillow_state_name IS NOT NULL
   AND UPPER(TRIM(zs.zillow_state_name)) = s_map.state_name_upper
LEFT JOIN zip_enriched AS ze
    ON long_f.geo_level_code = 'zip'
   AND LPAD(LEFT(REGEXP_REPLACE(TRIM(long_f.geo_id), '[^0-9]', ''), 5), 5, '0') = ze.id_zip

{% endmacro %}
