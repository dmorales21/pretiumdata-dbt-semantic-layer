-- TRANSFORM.DEV.REF_DISPOSITION_CHERRE_SUBJECT_BRIDGE
-- Replaces pretium-ai-dbt **EDW_PROD.MART.MART_DISPOSITION_CHERRE_SUBJECT_BRIDGE** (same grain: disposition_id).
-- Joins **concept_disposition_yield_property** to latest Cherre assessor × AVM rows from **TRANSFORM.FACT**
-- (read-only `source('transform_fact', …)` per ARCHITECTURE_RULES).
-- Gated with **`transform_dev_enable_disposition_yield_stack`** (same as yield concept + pricing MODEL).
{{ config(
    materialized='table',
    database='TRANSFORM',
    schema='DEV',
    alias='ref_disposition_cherre_subject_bridge',
    enabled=var('transform_dev_enable_disposition_yield_stack', false),
    tags=['transform', 'transform_dev', 'fund_opco', 'disposition', 'cherre', 'ref', 'replaces_edw_mart'],
    cluster_by=['disposition_id'],
) }}

WITH disp AS (
    SELECT * FROM {{ ref('concept_disposition_yield_property') }}
),

assessor_latest AS (
    SELECT *
    FROM {{ source('transform_fact', 'cherre_tax_assessor_property_all_ts') }}
    QUALIFY ROW_NUMBER() OVER (
        PARTITION BY tax_assessor_id
        ORDER BY data_publish_date DESC NULLS LAST
    ) = 1
),

avm_latest AS (
    SELECT *
    FROM {{ source('transform_fact', 'cherre_avm_property_all_ts') }}
    QUALIFY ROW_NUMBER() OVER (
        PARTITION BY tax_assessor_id
        ORDER BY valuation_date DESC NULLS LAST
    ) = 1
),

cherre AS (
    SELECT
        a.tax_assessor_id,
        a.cherre_parcel_id,
        a.state,
        a.zip,
        a.bed_count,
        a.building_sq_ft,
        v.confidence_score,
        a.latitude,
        a.longitude,
        a.property_use_standardized_code
    FROM assessor_latest AS a
    LEFT JOIN avm_latest AS v
        ON a.tax_assessor_id = v.tax_assessor_id
    WHERE a.property_use_standardized_code = '1001'
      AND v.confidence_score IS NOT NULL
      AND v.confidence_score >= 60
      AND a.building_sq_ft IS NOT NULL
      AND a.building_sq_ft > 0
      AND a.bed_count IS NOT NULL
      AND a.zip IS NOT NULL
      AND a.state IS NOT NULL
),

joined AS (
    SELECT
        d.disposition_id,
        d.tribeca_number,
        d.property_sfdc_id,
        c.tax_assessor_id,
        c.cherre_parcel_id,
        c.confidence_score AS cherre_match_confidence_score,
        c.latitude         AS cherre_latitude,
        c.longitude        AS cherre_longitude,
        'SUBJECT_ATTRIBUTE_MATCH'::VARCHAR(64) AS bridge_method
    FROM disp AS d
    LEFT JOIN cherre AS c
        ON UPPER(TRIM(COALESCE(d.state, ''))) = UPPER(TRIM(COALESCE(c.state, '')))
        AND LPAD(TRIM(COALESCE(TO_VARCHAR(d.zip_code), '')), 5, '0')
            = LPAD(TRIM(COALESCE(TO_VARCHAR(c.zip), '')), 5, '0')
        AND ABS(c.bed_count - COALESCE(d.bedrooms, 0)) <= 1
        AND (
            d.square_feet IS NULL
            OR d.square_feet <= 0
            OR ABS(c.building_sq_ft - d.square_feet) / NULLIF(d.square_feet::FLOAT, 0) <= 0.20
        )
    QUALIFY ROW_NUMBER() OVER (
        PARTITION BY d.disposition_id
        ORDER BY c.confidence_score DESC NULLS LAST, c.tax_assessor_id ASC
    ) = 1
)

SELECT
    disposition_id,
    tribeca_number,
    property_sfdc_id,
    tax_assessor_id,
    cherre_parcel_id,
    cherre_match_confidence_score,
    cherre_latitude,
    cherre_longitude,
    bridge_method,
    CURRENT_TIMESTAMP() AS dbt_updated_at
FROM joined
