-- TRANSFORM.DEV.TAX_FOUNDATION_PROPERTY_TAXES_BY_COUNTY — wide county tax (cleaned + county FIPS).
-- Parity with pretium-ai-dbt **tax_foundation_property_taxes_by_county** (cleaned) plus **county_fips** from REFERENCE.GEOGRAPHY.
-- Downstream: **fact_property_tax_by_county** (long).

{{ config(
    alias='tax_foundation_property_taxes_by_county',
    materialized='view',
    tags=['transform', 'transform_dev', 'tax_foundation', 'cleaned', 'place'],
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
        UNION ALL SELECT 'Delaware', 'DE'
        UNION ALL SELECT 'District of Columbia', 'DC'
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
        UNION ALL SELECT 'Washington D.C.', 'DC'
        UNION ALL SELECT 'Washington DC', 'DC'
        UNION ALL SELECT 'West Virginia', 'WV'
        UNION ALL SELECT 'Wisconsin', 'WI'
        UNION ALL SELECT 'Wyoming', 'WY'
    ) AS t
),

state_abbr_to_fips AS (
    SELECT 'AL' AS state_abbr, '01' AS state_fips UNION ALL SELECT 'AK', '02'
    UNION ALL SELECT 'AZ', '04' UNION ALL SELECT 'AR', '05' UNION ALL SELECT 'CA', '06'
    UNION ALL SELECT 'CO', '08' UNION ALL SELECT 'CT', '09' UNION ALL SELECT 'DE', '10'
    UNION ALL SELECT 'DC', '11' UNION ALL SELECT 'FL', '12' UNION ALL SELECT 'GA', '13'
    UNION ALL SELECT 'HI', '15' UNION ALL SELECT 'ID', '16' UNION ALL SELECT 'IL', '17'
    UNION ALL SELECT 'IN', '18' UNION ALL SELECT 'IA', '19' UNION ALL SELECT 'KS', '20'
    UNION ALL SELECT 'KY', '21' UNION ALL SELECT 'LA', '22' UNION ALL SELECT 'ME', '23'
    UNION ALL SELECT 'MD', '24' UNION ALL SELECT 'MA', '25' UNION ALL SELECT 'MI', '26'
    UNION ALL SELECT 'MN', '27' UNION ALL SELECT 'MS', '28' UNION ALL SELECT 'MO', '29'
    UNION ALL SELECT 'MT', '30' UNION ALL SELECT 'NE', '31' UNION ALL SELECT 'NV', '32'
    UNION ALL SELECT 'NH', '33' UNION ALL SELECT 'NJ', '34' UNION ALL SELECT 'NM', '35'
    UNION ALL SELECT 'NY', '36' UNION ALL SELECT 'NC', '37' UNION ALL SELECT 'ND', '38'
    UNION ALL SELECT 'OH', '39' UNION ALL SELECT 'OK', '40' UNION ALL SELECT 'OR', '41'
    UNION ALL SELECT 'PA', '42' UNION ALL SELECT 'RI', '44' UNION ALL SELECT 'SC', '45'
    UNION ALL SELECT 'SD', '46' UNION ALL SELECT 'TN', '47' UNION ALL SELECT 'TX', '48'
    UNION ALL SELECT 'UT', '49' UNION ALL SELECT 'VT', '50' UNION ALL SELECT 'VA', '51'
    UNION ALL SELECT 'WA', '53' UNION ALL SELECT 'WV', '54' UNION ALL SELECT 'WI', '55'
    UNION ALL SELECT 'WY', '56'
),

source_normalized AS (
    SELECT
        TRIM(COALESCE(STATE, '')) AS state_raw,
        TRIM(COALESCE(COUNTY, '')) AS county_raw,
        MEDIAN_HOUSING_VALUE_2023 AS median_housing_value_2023,
        MEDIAN_PROPERTY_TAXES_PAID_2023 AS median_property_taxes_paid_2023,
        EFFECTIVE_PROPERTY_TAX_RATE_2023 AS effective_property_tax_rate_2023,
        LOAD_DATE AS load_date
    FROM {{ source('tax_foundation', 'property_taxes_by_county_2025') }}
    WHERE TRIM(COALESCE(STATE, '')) != ''
      AND TRIM(COALESCE(COUNTY, '')) != ''
),

tax_cleaned AS (
    SELECT
        sc.state_code,
        TRIM(sn.county_raw) AS county_name,
        sn.median_housing_value_2023,
        sn.median_property_taxes_paid_2023,
        sn.effective_property_tax_rate_2023,
        sn.load_date,
        'TAX_FOUNDATION' AS vendor_name,
        'SOURCE_PROD.TAX_FOUNDATION.PROPERTY_TAXES_BY_COUNTY_2025' AS source_table
    FROM source_normalized AS sn
    INNER JOIN state_name_to_code AS sc
        ON sc.state_name = TRIM(REGEXP_REPLACE(sn.state_raw, '\\s*\\([a-z]\\)\\s*$', ''))
    WHERE sn.effective_property_tax_rate_2023 IS NOT NULL
       OR sn.median_housing_value_2023 IS NOT NULL
       OR sn.median_property_taxes_paid_2023 IS NOT NULL
),

county_dim AS (
    SELECT
        LPAD(TRIM(TO_VARCHAR(c.STATEFP)), 2, '0') AS state_fips,
        LPAD(TRIM(TO_VARCHAR(c.GEOID)), 5, '0') AS county_fips,
        TRIM(TO_VARCHAR(c.NAME)) AS county_name_geo
    FROM {{ source('reference_geography', 'county') }} AS c
    WHERE c.YEAR = {{ reference_geography_year() }}
      AND c.GEOID IS NOT NULL
)

SELECT
    t.state_code,
    t.county_name,
    d.county_fips,
    t.median_housing_value_2023,
    t.median_property_taxes_paid_2023,
    t.effective_property_tax_rate_2023,
    t.load_date,
    t.vendor_name,
    t.source_table,
    CURRENT_TIMESTAMP() AS cleaned_at
FROM tax_cleaned AS t
INNER JOIN state_abbr_to_fips AS m ON UPPER(TRIM(t.state_code)) = m.state_abbr
INNER JOIN county_dim AS d
    ON d.state_fips = m.state_fips
   AND (
        t.county_name = d.county_name_geo
        OR t.county_name || ' County' = d.county_name_geo
        OR t.county_name = REPLACE(d.county_name_geo, ' County', '')
    )
