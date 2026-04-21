-- TRANSFORM.DEV.FACT_COSTAR_MF_MARKET_CBSA_MONTHLY — read-through of Jon wide MF DataExport in **TRANSFORM.DEV**
-- (dataset **DS_034** — physical table commonly **FACT_COSTAR_CBSA_MONTHLY**; override **`transform_dev_costar_mf_market_identifier`**).
-- Column inventory: ``docs/migration/MIGRATION_TASKS_COSTAR.md`` §1.5. Register **MET_*** after ``DESCRIBE`` (WL_020 follow-up).
{{ config(
    alias='fact_costar_mf_market_cbsa_monthly',
    materialized='view',
    tags=['transform', 'transform_dev', 'costar', 'fact_costar', 'observe_only'],
) }}

SELECT *
FROM {{ source('transform_dev', 'fact_costar_cbsa_monthly') }}
