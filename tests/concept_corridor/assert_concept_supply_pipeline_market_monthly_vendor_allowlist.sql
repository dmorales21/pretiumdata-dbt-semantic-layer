-- Singular test: reject unknown vendor_code rows on long UNION ALL panel.
SELECT vendor_code, COUNT(*) AS row_count
FROM {{ ref('concept_supply_pipeline_market_monthly') }}
WHERE vendor_code NOT IN (
    'REALTOR',
    'ZILLOW_NEW_CONSTRUCTION',
    'MARKERR_RENT_LISTINGS',
    'MARKERR_RENT_LISTINGS_COUNTY',
    'RCA_MF_CONSTRUCTION',
    'RCA_MF_CONSTRUCTION_COUNTY',
    'ZONDA_SFR'
)
GROUP BY 1
