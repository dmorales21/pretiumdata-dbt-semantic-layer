-- TRANSFORM.DEV.CLEANED_QUADRANT_INSURANCE_STATE_RATES — state rates by dwelling (Quadrant).
-- Parity with pretium-ai-dbt **cleaned_quadrant_insurance_state_rates**.

{{ config(
    alias='cleaned_quadrant_insurance_state_rates',
    materialized='view',
    tags=['transform', 'transform_dev', 'quadrant', 'insurance', 'cleaned'],
) }}

WITH state_name_to_code AS (
    SELECT state_name, state_code FROM (
        SELECT 'Alabama' AS state_name, 'AL' AS state_code
        UNION ALL SELECT 'Alaska', 'AK'
        UNION ALL SELECT 'Arizona', 'AZ'
        UNION ALL SELECT 'Arkansas', 'AR'
        UNION ALL SELECT 'California', 'CA'
        UNION ALL SELECT 'Colorado', 'CO'
        UNION ALL SELECT 'Connecticut', 'CT'
        UNION ALL SELECT 'Washington D.C.', 'DC'
        UNION ALL SELECT 'District of Columbia', 'DC'
        UNION ALL SELECT 'Delaware', 'DE'
        UNION ALL SELECT 'Florida', 'FL'
        UNION ALL SELECT 'Georgia', 'GA'
        UNION ALL SELECT 'Hawaii', 'HI'
        UNION ALL SELECT 'Idaho', 'ID'
        UNION ALL SELECT 'Illinois', 'IL'
        UNION ALL SELECT 'Indiana', 'IN'
        UNION ALL SELECT 'Iowa', 'IA'
        UNION ALL SELECT 'Kansas', 'KS'
        UNION ALL SELECT 'Kentucky', 'KY'
        UNION ALL SELECT 'Louisiana', 'LA'
        UNION ALL SELECT 'Maine', 'ME'
        UNION ALL SELECT 'Maryland', 'MD'
        UNION ALL SELECT 'Massachusetts', 'MA'
        UNION ALL SELECT 'Michigan', 'MI'
        UNION ALL SELECT 'Minnesota', 'MN'
        UNION ALL SELECT 'Mississippi', 'MS'
        UNION ALL SELECT 'Missouri', 'MO'
        UNION ALL SELECT 'Montana', 'MT'
        UNION ALL SELECT 'Nebraska', 'NE'
        UNION ALL SELECT 'Nevada', 'NV'
        UNION ALL SELECT 'New Hampshire', 'NH'
        UNION ALL SELECT 'New Jersey', 'NJ'
        UNION ALL SELECT 'New Mexico', 'NM'
        UNION ALL SELECT 'New York', 'NY'
        UNION ALL SELECT 'North Carolina', 'NC'
        UNION ALL SELECT 'North Dakota', 'ND'
        UNION ALL SELECT 'Ohio', 'OH'
        UNION ALL SELECT 'Oklahoma', 'OK'
        UNION ALL SELECT 'Oregon', 'OR'
        UNION ALL SELECT 'Pennsylvania', 'PA'
        UNION ALL SELECT 'Rhode Island', 'RI'
        UNION ALL SELECT 'South Carolina', 'SC'
        UNION ALL SELECT 'South Dakota', 'SD'
        UNION ALL SELECT 'Tennessee', 'TN'
        UNION ALL SELECT 'Texas', 'TX'
        UNION ALL SELECT 'Utah', 'UT'
        UNION ALL SELECT 'Vermont', 'VT'
        UNION ALL SELECT 'Virginia', 'VA'
        UNION ALL SELECT 'Washington', 'WA'
        UNION ALL SELECT 'West Virginia', 'WV'
        UNION ALL SELECT 'Wisconsin', 'WI'
        UNION ALL SELECT 'Wyoming', 'WY'
    ) AS t
),

source_data AS (
    SELECT
        DATE_REFERENCE AS date_reference,
        TRIM(COALESCE(STATE, '')) AS state_raw,
        AVGRATE_200K AS avgrate_200k,
        AVGRATE_300K AS avgrate_300k,
        AVGRATE_400K AS avgrate_400k,
        AVGRATE_600K AS avgrate_600k,
        AVGRATE_1000K AS avgrate_1000k
    FROM {{ source('quadrant', 'insurance_state_rates') }}
    WHERE DATE_REFERENCE IS NOT NULL AND TRIM(COALESCE(STATE, '')) != ''
)

SELECT
    s.date_reference,
    x.state_code,
    s.state_raw AS state_name,
    s.avgrate_200k,
    s.avgrate_300k,
    s.avgrate_400k,
    s.avgrate_600k,
    s.avgrate_1000k,
    'QUADRANT' AS vendor_name,
    'SOURCE_PROD.QUADRANT.INSURANCE_STATE_RATES' AS source_table,
    CURRENT_TIMESTAMP() AS cleaned_at
FROM source_data AS s
INNER JOIN state_name_to_code AS x ON x.state_name = s.state_raw
