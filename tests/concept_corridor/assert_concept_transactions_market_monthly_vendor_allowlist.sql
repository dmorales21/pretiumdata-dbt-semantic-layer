-- Singular test: reject unknown vendor_code rows on long UNION ALL panel.
SELECT vendor_code, COUNT(*) AS row_count
FROM {{ ref('concept_transactions_market_monthly') }}
WHERE vendor_code NOT IN (
    'ZILLOW',
    'CHERRE_RECORDER_SFR',
    'CHERRE_RECORDER_MF',
    'RCA_MF_TRANSACTIONS',
    'ZONDA_DEEDS'
)
GROUP BY 1
