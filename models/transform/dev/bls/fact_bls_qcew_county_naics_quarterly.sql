-- TRANSFORM.DEV.FACT_BLS_QCEW_COUNTY_NAICS_QUARTERLY
-- Vendor/dataset: BLS / QCEW (SOURCE_PROD.BLS.QCEW_COUNTY_RAW).
-- Grain: county_fips × naics_2digit × year × quarter (ownership aggregated).
-- Metrics: employment (jobs), total_wages, establishments, avg_weekly_wage (derived).
-- Lineage parity: pretium-ai-dbt `cleaned_qcew_county_naics.sql` (filters + 2-digit NAICS including combined codes).
-- Governance: pretium-ai-dbt docs/governance/AI_REPLACEMENT_AND_AIGE_DATA_DEPENDENCIES.md §0 (distinct measurable concepts).

{{ config(
    alias='fact_bls_qcew_county_naics_quarterly',
    materialized='table',
    tags=['transform', 'transform_dev', 'bls', 'fact_bls', 'qcew', 'workforce_metrics', 'T-ANALYTICS-LABOR-AUTOMATION-RISK-STACK'],
) }}

with raw as (

    select
        -- QCEW VARIANT may expose FIPS as numeric (drop leading zeros); normalize to 5-char county FIPS
        lpad(trim(v:area_fips::varchar), 5, '0') as county_fips,
        v:industry_code::varchar(10)    as industry_code,
        v:industry_title::varchar(200)  as industry_title,
        v:own_code::varchar(5)          as own_code,
        v:year::integer                 as year,
        v:qtr::varchar(1)               as quarter_raw,
        v:month3_emplvl::float          as employment,
        v:total_qtrly_wages::float      as total_wages,
        v:qtrly_estabs::integer         as establishments

    from {{ source('source_prod_bls', 'qcew_county_raw') }}
    where v:area_fips is not null
      and trim(v:area_fips::varchar) != ''

),

filtered as (

    select
        county_fips,
        industry_code,
        replace(industry_title, 'NAICS ', '') as naics_title,
        year,
        try_to_number(quarter_raw)            as quarter,
        employment,
        total_wages,
        establishments

    from raw
    where
        length(trim(county_fips)) = 5
        and regexp_like(trim(county_fips), '^[0-9]{5}$')
        and right(trim(county_fips), 3) != '000'
        and (
            (
                len(industry_code) = 2
                and try_to_number(industry_code) is not null
                and try_to_number(industry_code) between 11 and 92
            )
            or industry_code in ('31-33', '44-45', '48-49')
        )
        and try_to_number(quarter_raw) is not null
        and year between 2022 and 2024
        and own_code in ('1', '2', '3', '5')
        and employment is not null
        and employment > 0

),

aggregated as (

    select
        county_fips,
        industry_code                                      as naics_2digit,
        max(naics_title)                                   as naics_title,
        year,
        quarter,
        dateadd(
            month,
            quarter * 3 - 1,
            date_from_parts(year, 1, 1)
        )                                                  as date_reference,
        sum(employment)                                    as employment,
        sum(total_wages)                                   as total_wages,
        sum(establishments)                                as establishments,
        round(
            sum(total_wages) / nullif(sum(employment) * 13, 0),
            2
        )                                                  as avg_weekly_wage

    from filtered
    group by county_fips, industry_code, year, quarter

)

select
    county_fips,
    naics_2digit,
    naics_title,
    year,
    quarter,
    date_reference,
    employment,
    total_wages,
    establishments,
    avg_weekly_wage

from aggregated
