-- Singular test: reject unknown vendor_code rows on concept_rent_property_monthly.
-- Pass: 0 rows. Fail: any vendor_code not in the explicit allowlist.
-- Contract source: models/transform/dev/concept/schema.yml — vendor_code column description.

{{ config(tags=['concept_corridor', 'rent', 'qa']) }}

SELECT
    vendor_code,
    COUNT(*) AS row_count
FROM {{ ref('concept_rent_property_monthly') }}
WHERE vendor_code NOT IN (
    'APARTMENTIQ',
    'CHERRE',
    'YARDI_MATRIX'
)
GROUP BY 1
