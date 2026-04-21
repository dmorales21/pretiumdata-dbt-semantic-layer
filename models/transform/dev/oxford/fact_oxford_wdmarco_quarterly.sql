-- TRANSFORM.DEV.FACT_OXFORD_WDMARCO_QUARTERLY — Oxford **WDMARCO** national (USA) long-form macro series.
-- (Common misspelling **WDMACRO** → correct vendor table / prefix **WDMARCO**.)
-- metric_id = 'WDMARCO_' || UPPER(Indicator_code); date_reference per profile doc §5 (same Period/Year logic as AMREG).
{{ config(
    alias='fact_oxford_wdmarco_quarterly',
    materialized='view',
    tags=['transform', 'transform_dev', 'oxford_economics', 'fact_oxford', 'wdmarco'],
) }}

WITH wd AS (
    SELECT
        TRY_CAST({{ adapter.quote('Year') }} AS INT) AS year_n,
        {{ adapter.quote('Period') }} AS period,
        TRY_CAST({{ adapter.quote('Data') }} AS FLOAT) AS value,
        TRIM({{ adapter.quote('Indicator_code') }}) AS indicator_code,
        TRIM({{ adapter.quote('Indicator') }}) AS indicator_name,
        TRIM({{ adapter.quote('Units') }}) AS units,
        TRIM({{ adapter.quote('Scale') }}) AS scale,
        TRIM({{ adapter.quote('Measurement') }}) AS measurement
    FROM {{ source('source_entity_pretium', 'wdmarco') }}
    WHERE {{ adapter.quote('Year') }} IS NOT NULL
      AND {{ adapter.quote('Data') }} IS NOT NULL
      AND TRIM({{ adapter.quote('Indicator_code') }}) IS NOT NULL
      AND TRIM({{ adapter.quote('Indicator_code') }}) <> ''
)

SELECT
    CASE
        WHEN w.period = 'Annual' THEN date_from_parts(w.year_n, 1, 1)
        ELSE date_from_parts(
            w.year_n,
            coalesce(
                CASE try_cast(regexp_substr(w.period, '[0-9]+') AS INT)
                    WHEN 1 THEN 1 WHEN 2 THEN 4 WHEN 3 THEN 7 WHEN 4 THEN 10
                    ELSE 1 END,
                1
            ),
            1
        )
    END AS date_reference,
    CASE WHEN w.period = 'Annual' THEN 'annual' ELSE 'quarterly' END AS frequency_code,
    CAST(NULL AS VARCHAR(10)) AS id_cbsa,
    CAST(NULL AS VARCHAR(500)) AS name_cbsa,
    'national' AS geo_level_code,
    'USA' AS geo_id,
    'WDMARCO_' || upper(w.indicator_code) AS metric_id,
    w.indicator_name AS metric_name,
    w.value AS value,
    nullif(
        trim(
            concat_ws(
                ' ',
                nullif(trim(w.units), ''),
                nullif(trim(w.scale), ''),
                nullif(trim(w.measurement), '')
            )
        ),
        ''
    ) AS unit,
    'oxford_economics' AS vendor_code
FROM wd AS w
