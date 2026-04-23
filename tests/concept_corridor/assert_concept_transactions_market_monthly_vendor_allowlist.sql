-- Singular test: reject unknown vendor_code rows on long UNION ALL panel.
SELECT vendor_code, COUNT(*) AS row_count
FROM {{ ref('concept_transactions_market_monthly') }}
WHERE vendor_code NOT IN (
    'ZILLOW',
    'CHERRE_RECORDER_SFR',
    'CHERRE_RECORDER_SFR_COUNTY',
    'CHERRE_RECORDER_MF',
    'CHERRE_RECORDER_MF_COUNTY',
    'RCA_MF_TRANSACTIONS',
    'RCA_MF_TRANSACTIONS_COUNTY',
    'ZONDA_DEEDS',
    'ZONDA_DEEDS_COUNTY',
    'ZONDA_SFR',
    'ZONDA_SFR_COUNTY'
)
GROUP BY 1
