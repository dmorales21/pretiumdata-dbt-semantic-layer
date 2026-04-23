-- Singular test: reject unknown vendor_code rows on concept_rent_market_monthly UNION.
-- Pass: 0 rows. Fail: any vendor_code not in the explicit allowlist (union drift / typo guard).
-- Contract source: models/transform/dev/concept/schema.yml — vendor_code column description.

{{ config(tags=['concept_corridor', 'rent', 'qa']) }}

SELECT
    vendor_code,
    COUNT(*) AS row_count
FROM {{ ref('concept_rent_market_monthly') }}
WHERE vendor_code NOT IN (
    'ZILLOW',
    'APARTMENTIQ',
    'YARDI_MATRIX',
    'COSTAR',
    'markerr',
    'HUD_CYBERSYN',
    'CHERRE'
)
GROUP BY 1
