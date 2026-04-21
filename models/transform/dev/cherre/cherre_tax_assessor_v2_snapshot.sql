-- TRANSFORM.DEV — passthrough over TRANSFORM.CHERRE.TAX_ASSESSOR_V2_SNAPSHOT (often a Dynamic Table).
{{ config(
    alias = 'CHERRE_TAX_ASSESSOR_V2_SNAPSHOT',
    materialized = 'view',
    tags = ['transform', 'transform_dev', 'cherre', 'cherre_read_surface']
) }}

select *
from {{ source('cherre_transform', 'TAX_ASSESSOR_V2_SNAPSHOT') }}
