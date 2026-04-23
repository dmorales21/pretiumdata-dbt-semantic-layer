-- Guardrail: keep workflow/panel aliases out of active canonical concept vocabulary.
-- If transitional aliases are retained for backward compatibility, they must stay inactive.

SELECT
    concept_id,
    concept_code,
    concept_label,
    is_active
FROM {{ ref('concept') }}
WHERE concept_code IN (
    'fund_property_spine',
    'acquisition_underwriting',
    'spine',
    'underwriting',
    'multifamily_market'
)
  AND COALESCE(is_active, FALSE)
