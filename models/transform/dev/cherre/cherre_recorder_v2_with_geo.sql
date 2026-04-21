-- TRANSFORM.DEV — passthrough read surface over TRANSFORM.CHERRE.RECORDER_V2_WITH_GEO (often a Dynamic Table).
{{ config(
    alias = 'CHERRE_RECORDER_V2_WITH_GEO',
    materialized = 'view',
    tags = ['transform', 'transform_dev', 'cherre', 'cherre_read_surface']
) }}

select *
from {{ source('cherre_transform', 'RECORDER_V2_WITH_GEO') }}
