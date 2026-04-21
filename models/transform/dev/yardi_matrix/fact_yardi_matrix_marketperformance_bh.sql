-- TRANSFORM.DEV.FACT_YARDI_MATRIX_MARKETPERFORMANCE_BH — read-through of **TRANSFORM.YARDI_MATRIX.MARKETPERFORMANCE_BH**.
-- Long-form market KPIs (``DATATYPE`` / ``DATAVALUE``); rent-like rows filtered in ``concept_rent_market_monthly``. WL_020 **MET_046**.
{{ config(
    alias='fact_yardi_matrix_marketperformance_bh',
    materialized='view',
    tags=['transform', 'transform_dev', 'yardi', 'yardi_matrix', 'fact_yardi_matrix'],
) }}

SELECT *
FROM {{ source('transform_yardi_matrix', 'marketperformance_bh') }}
