-- TRANSFORM.DEV.FACT_YARDI_MATRIX_SUBMARKETMATCH_ZIPZCTA_BH — read-through of **TRANSFORM.YARDI_MATRIX.SUBMARKETMATCHZIPZCTA_BH**.
-- ZIP ↔ submarket bridge for ``concept_rent_market_monthly`` Yardi Matrix path (WL_020 / graph edge).
{{ config(
    alias='fact_yardi_matrix_submarketmatch_zipzcta_bh',
    materialized='view',
    tags=['transform', 'transform_dev', 'yardi_matrix', 'fact_yardi_matrix'],
) }}

SELECT *
FROM {{ source('transform_yardi_matrix', 'submarketmatchzipzcta_bh') }}
