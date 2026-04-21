-- BLS QCEW × O*NET bridge: estimated county × SOC employment and annual wage bill.
-- Port of pretium-ai-dbt `fact_county_soc_employment.sql`; QCEW input is
-- `fact_bls_qcew_county_naics_quarterly` (same grain/filters as legacy cleaned QCEW).
-- Staffing bridge: `source('transform_dev_vendor_ref','ref_onet_soc_to_naics')` — land with
-- `docs/migration/sql/create_ref_onet_soc_to_naics_transform_dev.sql`.
-- Grain: county_fips × onet_soc_code (2024 annual average from four quarters).

{{ config(
    alias='FACT_COUNTY_SOC_EMPLOYMENT',
    materialized='table',
    tags=['transform', 'transform_dev', 'bls', 'onet', 'qcew', 'T-ANALYTICS-LABOR-AUTOMATION-RISK-STACK'],
    cluster_by=['county_fips'],
) }}

with qcew_2024_avg as (

    select
        county_fips,
        naics_2digit,
        naics_title,
        avg(employment)   as avg_employment,
        avg(total_wages)  as avg_quarterly_wages

    from {{ ref('fact_bls_qcew_county_naics_quarterly') }}
    where year = 2024
      and length(trim(county_fips)) = 5
      and regexp_like(trim(county_fips), '^[0-9]{5}$')
      and right(trim(county_fips), 3) != '000'
    group by county_fips, naics_2digit, naics_title

),

bridge_raw as (
    select
        onet_soc_code,
        occupation_title,
        naics_code,
        employment_share::float as employment_share
    from {{ source('transform_dev_vendor_ref', 'ref_onet_soc_to_naics') }}
    where naics_level = 2
),

bridge_normalized as (
    select
        onet_soc_code,
        occupation_title,
        naics_code,
        employment_share,
        employment_share / nullif(sum(employment_share) over (partition by naics_code), 0)
            as naics_staffing_proportion
    from bridge_raw
),

allocated as (

    select
        q.county_fips,
        b.onet_soc_code,
        b.occupation_title,
        q.naics_2digit,
        q.naics_title,
        round(q.avg_employment * b.naics_staffing_proportion, 1)     as soc_employment_from_naics,
        round(q.avg_quarterly_wages * b.naics_staffing_proportion * 4, 0) as soc_annual_wages_from_naics

    from qcew_2024_avg q
    inner join bridge_normalized b
        on q.naics_2digit = b.naics_code

),

aggregated as (

    select
        county_fips,
        onet_soc_code,
        max(occupation_title)                               as occupation_title,
        round(sum(soc_employment_from_naics), 1)            as estimated_employment,
        round(sum(soc_annual_wages_from_naics), 0)          as estimated_annual_wage_bill,
        listagg(distinct naics_2digit, '|')
            within group (order by naics_2digit)            as naics_source_codes,
        count(distinct naics_2digit)                        as naics_source_count

    from allocated
    group by county_fips, onet_soc_code

),

exposure_socs as (
    select distinct onet_soc_code from {{ ref('fact_dol_onet_soc_ai_exposure') }}
)

select
    a.county_fips,
    a.onet_soc_code,
    a.occupation_title,
    a.estimated_employment,
    a.estimated_annual_wage_bill,
    a.naics_source_codes,
    a.naics_source_count,
    case when ex.onet_soc_code is null then 1 else 0 end   as is_imputed_exposure,
    2024                                                    as data_year

from aggregated a
left join exposure_socs ex on a.onet_soc_code = ex.onet_soc_code
where a.estimated_employment > 0
