-- TRANSFORM.DEV.FACT_ZONDA_BTR_RENT_CBSA_MONTHLY_CLEANED — Zonda BTR project + floorplan → CBSA × month.
-- Logic aligned with **pretium-ai-dbt** ``cleaned_zonda_btr_rent_cbsa.sql`` (unit-weighted rent, occupancy 0–1).
{{ config(
    alias='fact_zonda_btr_rent_cbsa_monthly_cleaned',
    materialized='view',
    tags=['transform', 'transform_dev', 'zonda', 'fact_zonda', 'rent'],
) }}

WITH project_cbsa AS (

    SELECT
        UNIVERSALID,
        MAX(CBSAFIPSCODE)                                   AS cbsafipscode_raw,
        MAX(CBSA)                                           AS cbsa_name
    FROM {{ source('tpanalytics_share', 'zonda_btr_floorplans') }}
    WHERE CBSAFIPSCODE IS NOT NULL
      AND TRIM(CBSAFIPSCODE) NOT IN ('', 'nan')
    GROUP BY UNIVERSALID

),

comprehensive AS (

    SELECT
        c.UNIVERSALID,
        TO_DATE(c.ASOF)                                     AS date_reference,
        TRY_TO_DECIMAL(c.RENTAVG,        10, 2)             AS project_rent,
        TRY_TO_DECIMAL(c.OCCUPIEDPERCENT, 6, 4)             AS occupancy_pct_0_100,
        TRY_TO_NUMBER (c.OVERALLPLANNED)                    AS total_units
    FROM {{ source('tpanalytics_share', 'zonda_btr_comprehensive') }} AS c
    WHERE c.LEASINGSTATUS IN ('Stabilized', 'Lease-up')
      AND TRY_TO_DECIMAL(c.RENTAVG, 10, 2) IS NOT NULL
      AND TRY_TO_NUMBER(c.OVERALLPLANNED) > 0

),

joined AS (

    SELECT
        LPAD(
            SPLIT_PART(p.cbsafipscode_raw, '.', 1),
            5, '0'
        )                                                   AS cbsa_code,
        p.cbsa_name,
        c.date_reference,
        c.project_rent,
        c.occupancy_pct_0_100,
        c.total_units
    FROM comprehensive AS c
    INNER JOIN project_cbsa AS p
        ON c.UNIVERSALID = p.UNIVERSALID

)

SELECT
    cbsa_code,
    date_reference,
    MAX(cbsa_name)                                          AS metro_name,

    ROUND(
        SUM(project_rent * total_units)
        / NULLIF(SUM(total_units), 0),
        2
    )                                                       AS btr_avg_rent,

    ROUND(AVG(occupancy_pct_0_100) / 100.0, 5)             AS btr_occupancy_pct,

    ROUND(1.0 - AVG(occupancy_pct_0_100) / 100.0, 5)       AS btr_vacancy_pct,

    NULL::DECIMAL(6, 3)                                     AS btr_rent_growth_yoy_pct,

    COUNT(*)                                                AS project_count,
    SUM(total_units)                                        AS total_units,

    FALSE                                                   AS is_mdivision_average,

    'ZONDA'                                                 AS data_source,
    CURRENT_TIMESTAMP()                                     AS _loaded_at

FROM joined
GROUP BY cbsa_code, date_reference
HAVING btr_avg_rent IS NOT NULL
