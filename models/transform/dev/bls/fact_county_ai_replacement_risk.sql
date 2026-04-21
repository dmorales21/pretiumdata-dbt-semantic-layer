-- County-level AI workforce displacement risk (three scores + companion metrics).
-- Port of pretium-ai-dbt `fact_county_ai_replacement_risk.sql`.
-- QCEW cognitive-sector trend: **fact_bls_qcew_county_naics_quarterly** (NAICS 51,52,54,55,56).
-- County names + CBSA: **REFERENCE.GEOGRAPHY** `county`, `state`, `county_cbsa_xwalk` (year from `reference_geography_year()`).
-- Exposure: **fact_dol_onet_soc_ai_exposure**; employment: **fact_county_soc_employment**.

{{ config(
    alias='FACT_COUNTY_AI_REPLACEMENT_RISK',
    materialized='table',
    tags=['transform', 'transform_dev', 'bls', 'onet', 'qcew', 'T-ANALYTICS-LABOR-AUTOMATION-RISK-STACK'],
    cluster_by=['county_fips'],
) }}

with county_soc as (

    select
        e.county_fips,
        e.onet_soc_code,
        e.occupation_title,
        e.estimated_employment,
        e.estimated_annual_wage_bill,
        e.data_year,
        x.raw_activity_exposure,
        x.friction_adjusted_exposure,
        x.friction_index,
        x.exposure_tier,
        x.epoch_capability_coverage,
        x.is_augmentation_dominant,
        nullif(e.estimated_annual_wage_bill, 0)
            / nullif(e.estimated_employment, 0)        as annual_wage_per_worker

    from {{ ref('fact_county_soc_employment') }} e
    inner join {{ ref('fact_dol_onet_soc_ai_exposure') }} x
        using (onet_soc_code)
    where e.estimated_employment > 0

),

county_agg as (

    select
        county_fips,
        max(data_year)                                 as data_year,
        count(distinct onet_soc_code)                  as soc_count,
        sum(estimated_employment)                      as total_employment,
        sum(estimated_annual_wage_bill)                as total_wage_bill,

        round(
            sum(estimated_employment * raw_activity_exposure)
            / nullif(sum(estimated_employment), 0),
            4
        )                                              as raw_susceptibility,

        round(
            sum(estimated_employment * friction_adjusted_exposure)
            / nullif(sum(estimated_employment), 0),
            4
        )                                              as deployment_adjusted_exposure,

        round(
            sum(estimated_employment * epoch_capability_coverage)
            / nullif(sum(estimated_employment), 0),
            4
        )                                              as epoch_breadth_score,

        sum(
            case when exposure_tier in ('HIGH', 'VERY_HIGH')
            then estimated_employment else 0 end
        )                                              as exposed_employment,

        sum(
            case when exposure_tier in ('HIGH', 'VERY_HIGH')
            then estimated_annual_wage_bill else 0 end
        )                                              as exposed_wage_bill,

        round(
            sum(case when exposure_tier in ('HIGH', 'VERY_HIGH')
                     then estimated_annual_wage_bill else 0 end)
            / nullif(sum(estimated_annual_wage_bill), 0),
            4
        )                                              as shock_magnitude,

        sum(case when exposure_tier in ('HIGH', 'VERY_HIGH')
                 then estimated_annual_wage_bill else 0 end)
        / nullif(
            sum(case when exposure_tier in ('HIGH', 'VERY_HIGH')
                     then estimated_employment else 0 end),
            0
        )                                              as exposed_mean_annual_wage,

        sum(estimated_annual_wage_bill)
        / nullif(sum(estimated_employment), 0)         as county_mean_annual_wage

    from county_soc
    group by county_fips

),

wage_fragility_raw as (

    select
        county_fips,
        greatest(0.0,
            least(1.0,
                1.0 - (exposed_mean_annual_wage / nullif(county_mean_annual_wage, 0))
            )
        )                                              as fragility_raw
    from county_agg
    where exposed_mean_annual_wage is not null

),

fragility_norms as (

    select
        min(fragility_raw)                             as fragility_min,
        max(fragility_raw)                             as fragility_max
    from wage_fragility_raw

),

wage_fragility as (

    select
        w.county_fips,
        w.fragility_raw,
        round(
            (w.fragility_raw - n.fragility_min)
            / nullif(n.fragility_max - n.fragility_min, 0),
            4
        )                                              as wage_fragility_normalized
    from wage_fragility_raw w
    cross join fragility_norms n

),

county_scores as (

    select
        a.*,
        coalesce(w.wage_fragility_normalized, 0.5)     as wage_fragility_index,
        round(
            a.deployment_adjusted_exposure
                * (0.6 + 0.4 * coalesce(w.wage_fragility_normalized, 0.5)),
            4
        )                                              as combined_risk_score
    from county_agg a
    left join wage_fragility w using (county_fips)

),

risk_floors as (

    select
        percentile_cont(0.80) within group (order by combined_risk_score) as tier_high_floor,
        percentile_cont(0.50) within group (order by combined_risk_score) as tier_medium_floor
    from county_scores

),

soc_ranked as (

    select
        county_fips,
        occupation_title,
        onet_soc_code,
        round(estimated_employment)                    as occ_employment,
        friction_adjusted_exposure,
        row_number() over (
            partition by county_fips
            order by estimated_employment * friction_adjusted_exposure desc,
                     onet_soc_code asc
        )                                              as rank_in_county
    from county_soc

),

top_occupations as (

    select
        county_fips,
        max(case when rank_in_county = 1
                 then occupation_title
                      || ' (' || occ_employment::varchar || ' workers, '
                      || round(friction_adjusted_exposure * 100)::varchar || '% adj-exp)'
            end)                                       as top_occupation_1,
        max(case when rank_in_county = 2
                 then occupation_title
                      || ' (' || occ_employment::varchar || ' workers, '
                      || round(friction_adjusted_exposure * 100)::varchar || '% adj-exp)'
            end)                                       as top_occupation_2,
        max(case when rank_in_county = 3
                 then occupation_title
                      || ' (' || occ_employment::varchar || ' workers, '
                      || round(friction_adjusted_exposure * 100)::varchar || '% adj-exp)'
            end)                                       as top_occupation_3
    from soc_ranked
    where rank_in_county <= 3
    group by county_fips

),

trend_base as (

    select
        county_fips,
        date_reference,
        sum(employment)                                as sector_employment
    from {{ ref('fact_bls_qcew_county_naics_quarterly') }}
    where naics_2digit in ('51', '52', '54', '55', '56')
    group by county_fips, date_reference

),

trend_anchors as (

    select
        county_fips,
        min(date_reference)                            as oldest_date,
        max(date_reference)                            as latest_date,
        count(distinct date_reference)                 as quarter_count
    from trend_base
    group by county_fips
    having count(distinct date_reference) >= 6

),

trend_8q as (

    select
        t.county_fips,
        round(max(case when t.date_reference = a.oldest_date
                       then t.sector_employment end), 0) as trend_emp_8q_ago,
        round(max(case when t.date_reference = a.latest_date
                       then t.sector_employment end), 0) as trend_emp_latest,
        round(
            (
                max(case when t.date_reference = a.latest_date
                         then t.sector_employment end)
              - max(case when t.date_reference = a.oldest_date
                         then t.sector_employment end)
            )
            / nullif(
                max(case when t.date_reference = a.oldest_date
                         then t.sector_employment end),
                0
            ),
            4
        )                                              as trend_8q_pct_change
    from trend_base t
    inner join trend_anchors a using (county_fips)
    group by t.county_fips

),

county_names as (

    select
        lpad(trim(to_varchar(c.geoid)), 5, '0')        as county_fips,
        max(trim(to_varchar(c.name)))                  as county_name,
        max(lpad(trim(to_varchar(c.statefp)), 2, '0')) as state_fips,
        max(trim(to_varchar(s.name)))                  as name_state
    from {{ source('reference_geography', 'county') }} c
    left join {{ source('reference_geography', 'state') }} s
        on lpad(trim(to_varchar(c.statefp)), 2, '0') = lpad(trim(to_varchar(s.geoid)), 2, '0')
        and s.year = {{ reference_geography_year() }}
    where c.year = {{ reference_geography_year() }}
      and c.geoid is not null
    group by lpad(trim(to_varchar(c.geoid)), 5, '0')

),

county_cbsa as (

    select
        county_fips,
        case
            when id_cbsa is not null and county_fips != id_cbsa then id_cbsa
        end                                            as cbsa_code,
        case
            when id_cbsa is not null and county_fips != id_cbsa then name_cbsa
        end                                            as name_cbsa
    from (
        select
            lpad(trim(to_varchar(x.county_fips)), 5, '0')     as county_fips,
            lpad(trim(to_varchar(x.cbsa_code)), 5, '0')       as id_cbsa,
            trim(to_varchar(x.cbsa_name))                    as name_cbsa,
            row_number() over (
                partition by lpad(trim(to_varchar(x.county_fips)), 5, '0')
                order by
                    case when x.cbsa_code is null then 1 else 0 end,
                    trim(to_varchar(x.cbsa_name)) asc nulls last,
                    lpad(trim(to_varchar(x.cbsa_code)), 5, '0') asc nulls last
            )                                               as rn
        from {{ source('reference_geography', 'county_cbsa_xwalk') }} x
        where x.year = {{ reference_geography_year() }}
          and x.county_fips is not null
    ) z
    where rn = 1

)

select
    s.county_fips,
    cn.county_name,
    cn.state_fips,
    cn.name_state,
    cc.cbsa_code,
    lpad(trim(to_varchar(cc.cbsa_code)), 5, '0')        as cbsa_id,
    cc.name_cbsa                                       as cbsa_name,

    round(s.total_employment, 0)                       as total_employment,
    round(s.total_wage_bill, 0)                        as total_wage_bill,
    s.soc_count,

    s.raw_susceptibility,
    s.deployment_adjusted_exposure,
    s.combined_risk_score,

    case
        when s.combined_risk_score >= f.tier_high_floor   then 'HIGH'
        when s.combined_risk_score >= f.tier_medium_floor then 'MEDIUM'
        else                                                   'LOW'
    end                                                as risk_tier,

    round(f.tier_high_floor, 4)                        as tier_high_floor,
    round(f.tier_medium_floor, 4)                      as tier_medium_floor,

    s.epoch_breadth_score,
    s.shock_magnitude,
    s.wage_fragility_index,
    round(s.exposed_employment, 0)                     as exposed_employment,
    round(s.exposed_wage_bill, 0)                      as exposed_wage_bill,

    t.trend_emp_8q_ago,
    t.trend_emp_latest,
    t.trend_8q_pct_change,
    case
        when t.trend_8q_pct_change < -0.05             then 'DECLINING'
        when t.trend_8q_pct_change >  0.05             then 'GROWING'
        when t.trend_8q_pct_change is null             then 'INSUFFICIENT_DATA'
        else                                                'STABLE'
    end                                                as trend_8q_direction,

    o.top_occupation_1,
    o.top_occupation_2,
    o.top_occupation_3,

    s.data_year,
    current_timestamp()                                as updated_at,
    'v1_county_pilot'                                  as methodology_version

from county_scores s
cross join risk_floors f
left join trend_8q t       using (county_fips)
left join top_occupations o using (county_fips)
left join county_names cn  using (county_fips)
left join county_cbsa cc   using (county_fips)
