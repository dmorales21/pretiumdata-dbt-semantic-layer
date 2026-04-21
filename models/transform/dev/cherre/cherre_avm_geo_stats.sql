-- TRANSFORM.DEV — passthrough over TRANSFORM.CHERRE.USA_AVM_GEO_STATS (AVM geo aggregates; often a Dynamic Table).
-- Parcel-level AVM time series remain on Jon base table USA_AVM_V2 until a separate FACT_ is ported.
{{ config(
    alias = 'CHERRE_AVM_GEO_STATS',
    materialized = 'view',
    tags = ['transform', 'transform_dev', 'cherre', 'cherre_read_surface', 'cherre_avm']
) }}

select *
from {{ source('cherre_transform', 'USA_AVM_GEO_STATS') }}
