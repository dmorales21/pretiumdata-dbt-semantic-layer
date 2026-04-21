-- TRANSFORM.DEV.FACT_OXFORD_AMREG_QUARTERLY — AMREG at Pretium CBSA grain (MSA rows × crosswalk only).
-- metric_id = 'AMREG_' || UPPER(Indicator_code); date_reference = quarter/year start per profile doc §5.
-- MSAD / state / country rows are excluded here (no crosswalk match); see OXFORD_SOURCE_ENTITY_PROFILE_AND_CROSSWALK_JOIN.md §4.2.
{{ config(
    alias='fact_oxford_amreg_quarterly',
    materialized='view',
    tags=['transform', 'transform_dev', 'oxford_economics', 'fact_oxford', 'amreg'],
) }}

WITH amreg AS (
    SELECT
        TRIM({{ adapter.quote('Location_code') }}) AS oxford_location_code,
        {{ adapter.quote('Region_Type') }} AS region_type,
        TRY_CAST({{ adapter.quote('Year') }} AS INT) AS year_n,
        {{ adapter.quote('Period') }} AS period,
        TRY_CAST({{ adapter.quote('Data') }} AS FLOAT) AS value,
        TRIM({{ adapter.quote('Indicator_code') }}) AS indicator_code,
        TRIM({{ adapter.quote('Indicator') }}) AS indicator_name,
        TRIM({{ adapter.quote('Units') }}) AS units,
        TRIM({{ adapter.quote('Scale') }}) AS scale,
        TRIM({{ adapter.quote('Measurement') }}) AS measurement
    FROM {{ source('source_entity_pretium', 'amreg') }}
    WHERE {{ adapter.quote('Year') }} IS NOT NULL
      AND {{ adapter.quote('Data') }} IS NOT NULL
      AND {{ adapter.quote('Region_Type') }} = 'MSA'
      AND TRIM({{ adapter.quote('Indicator_code') }}) IS NOT NULL
      AND TRIM({{ adapter.quote('Indicator_code') }}) <> ''
)

SELECT
    CASE
        WHEN a.period = 'Annual' THEN date_from_parts(a.year_n, 1, 1)
        ELSE date_from_parts(
            a.year_n,
            coalesce(
                CASE try_cast(regexp_substr(a.period, '[0-9]+') AS INT)
                    WHEN 1 THEN 1 WHEN 2 THEN 4 WHEN 3 THEN 7 WHEN 4 THEN 10
                    ELSE 1 END,
                1
            ),
            1
        )
    END AS date_reference,
    CASE WHEN a.period = 'Annual' THEN 'annual' ELSE 'quarterly' END AS frequency_code,
    xw.id_cbsa AS id_cbsa,
    xw.name_cbsa AS name_cbsa,
    'cbsa' AS geo_level_code,
    xw.id_cbsa AS geo_id,
    'AMREG_' || upper(a.indicator_code) AS metric_id,
    a.indicator_name AS metric_name,
    a.value AS value,
    nullif(
        trim(
            concat_ws(
                ' ',
                nullif(trim(a.units), ''),
                nullif(trim(a.scale), ''),
                nullif(trim(a.measurement), '')
            )
        ),
        ''
    ) AS unit,
    'oxford_economics' AS vendor_code
FROM amreg AS a
INNER JOIN {{ ref('ref_oxford_metro_cbsa') }} AS xw
    ON a.oxford_location_code = xw.oxford_location_code
    AND a.region_type = xw.oxford_region_type
