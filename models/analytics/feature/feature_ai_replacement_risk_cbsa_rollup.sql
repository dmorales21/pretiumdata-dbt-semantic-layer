-- FEATURE: CBSA-level rollup (one row per date_reference × cbsa_code) for LDI / DDS.
-- Legacy: employment-weighted `combined_ai_risk_score` over all NAICS rows in `feature_ai_replacement_risk_cbsa`.
-- Canonical: aggregates the synthetic **`naics_code = 'ALL'`** rows from the semantic `feature_ai_replacement_risk_cbsa`.

{{ config(
    materialized='view',
    alias='feature_ai_replacement_risk_cbsa_rollup',
    tags=['analytics', 'feature', 'ai_risk', 'cbsa', 'ldi_input', 'T-ANALYTICS-LABOR-AUTOMATION-RISK-STACK'],
) }}

{% if var('onet_soc_naics_enabled', false) %}

select
    date_reference,
    cbsa_code,
    replacement_risk_score,
    total_employment,
    created_at
from (
    select
        date_reference,
        cbsa_code,
        sum(combined_ai_risk_score * nullif(employment_level, 0))
            / nullif(sum(employment_level), 0)       as replacement_risk_score,
        sum(employment_level)                        as total_employment,
        current_timestamp()                          as created_at
    from {{ ref('feature_ai_replacement_risk_cbsa') }}
    where combined_ai_risk_score is not null
      and employment_level > 0
      and naics_code = 'ALL'
    group by date_reference, cbsa_code
) z
where z.replacement_risk_score is not null

{% else %}

select
    cast(null as date)                                 as date_reference,
    cast(null as varchar)                              as cbsa_code,
    cast(null as float)                                as replacement_risk_score,
    cast(null as float)                                as total_employment,
    current_timestamp()                                as created_at
where 1 = 0

{% endif %}
