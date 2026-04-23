-- =============================================================================
-- Catalog health inventory — 20 ad hoc checks (Snowflake / REFERENCE.CATALOG)
-- =============================================================================
-- **Hard-fail dbt singulars (subset):** Q6, Q7, Q11, Q19 are enforced in CI via
-- `tests/catalog/assert_*.sql` with tag **catalog_hard_gate** and `dbt compile --select tag:catalog_hard_gate`.
-- =============================================================================
-- Run sections selectively in a worksheet or materialize as views for monitoring.
-- Conventions:
--   * **Active** booleans: treat TRUE / 'TRUE' / '1' / 'T' as active (seed CSV variance).
--   * **METRIC_CATEGORY** in this repo: small enum lives in **catalog_enum** (`enum_table = 'metric_category'`);
--     physical table is often **REFERENCE.CATALOG.ENUM** (alias **enum**) after `dbt run --select catalog_enum`.
--   * **METRIC_DERIVED_SOURCE** in your wording → **REFERENCE.CATALOG.METRIC_DERIVED_INPUT** (bridge of
--     derived graphs to upstream **metric_code** rows). Adjust joins if your warehouse uses another name.
--   * **pipeline_status** on **dataset** is transform stage (transform_ready, transform_dev, …), not a
--     lifecycle “active” flag — use **data_status_code** for that. Section 18 includes both patterns.
-- =============================================================================

-- -----------------------------------------------------------------------------
-- 1–5 Referential integrity (orphan FKs on METRIC / DATASET)
-- -----------------------------------------------------------------------------

-- 1) METRIC.concept_code not in CONCEPT
select m.metric_code, m.concept_code
from reference.catalog.metric as m
left join reference.catalog.concept as c
    on c.concept_code = m.concept_code
where c.concept_code is null;

-- 2) METRIC.geo_level_code not in GEO_LEVEL
select m.metric_code, m.geo_level_code
from reference.catalog.metric as m
left join reference.catalog.geo_level as g
    on g.geo_level_code = m.geo_level_code
where g.geo_level_code is null;

-- 3) DATASET.vendor_code not in VENDOR
select d.dataset_code, d.vendor_code
from reference.catalog.dataset as d
left join reference.catalog.vendor as v
    on v.vendor_code = d.vendor_code
where v.vendor_code is null;

-- 4) METRIC.frequency_code not in FREQUENCY
select m.metric_code, m.frequency_code
from reference.catalog.metric as m
left join reference.catalog.frequency as f
    on f.frequency_code = m.frequency_code
where f.frequency_code is null;

-- 5) METRIC.metric_category_code not in METRIC_CATEGORY vocabulary (ENUM slice)
select m.metric_code, m.metric_category_code
from reference.catalog.metric as m
left join reference.catalog.enum as e
    on e.enum_table = 'metric_category'
    and e.code = m.metric_category_code
where m.metric_category_code is not null
    and trim(m.metric_category_code) <> ''
    and e.code is null;

-- If ENUM table not built yet, substitute:
-- left join (select distinct code as category_code from reference.catalog.catalog_enum_source where enum_table = 'metric_category') mc ...

-- -----------------------------------------------------------------------------
-- 6–10 Active row completeness gates
-- -----------------------------------------------------------------------------

-- 6) Active METRIC with null/empty table_path or snowflake_column
select
    m.metric_code,
    m.table_path,
    m.snowflake_column
from reference.catalog.metric as m
where upper(trim(to_varchar(m.is_active))) in ('TRUE', '1', 'T')
    and (
        m.table_path is null
        or trim(to_varchar(m.table_path)) = ''
        or m.snowflake_column is null
        or trim(to_varchar(m.snowflake_column)) = ''
    );

-- 7) Active DATASET, MotherDuck-served, missing last_refresh_date
select d.dataset_code, d.last_refresh_date, d.is_motherduck_served
from reference.catalog.dataset as d
where upper(trim(to_varchar(d.is_active))) in ('TRUE', '1', 'T')
    and upper(trim(to_varchar(d.is_motherduck_served))) in ('TRUE', '1', 'T')
    and (
        d.last_refresh_date is null
        or trim(to_varchar(d.last_refresh_date)) = ''
    );

-- 8) Active VENDOR with null contract_status
select v.vendor_code, v.contract_status
from reference.catalog.vendor as v
where upper(trim(to_varchar(v.is_active))) in ('TRUE', '1', 'T')
    and (
        v.contract_status is null
        or trim(to_varchar(v.contract_status)) = ''
    );

-- 9) Active METRIC where unit not in catalog allowlist (keep in sync with schema_metric.yml)
with allowed_unit (unit) as (
    select column1
    from values
        ('boolean'),
        ('bp'),
        ('count'),
        ('days'),
        ('index'),
        ('pct'),
        ('ratio'),
        ('sqft'),
        ('usd'),
        ('varies'),
        ('years')
)
select m.metric_code, m.unit
from reference.catalog.metric as m
left join allowed_unit as u
    on u.unit = lower(trim(to_varchar(m.unit)))
where upper(trim(to_varchar(m.is_active))) in ('TRUE', '1', 'T')
    and u.unit is null;

-- 10) Active CONCEPT with null/empty domain
select c.concept_code, c.domain
from reference.catalog.concept as c
where upper(trim(to_varchar(c.is_active))) in ('TRUE', '1', 'T')
    and (
        c.domain is null
        or trim(to_varchar(c.domain)) = ''
    );

-- -----------------------------------------------------------------------------
-- 11 Promotion gate (metric_raw → metric)
-- -----------------------------------------------------------------------------

-- 11) METRIC_RAW active + governance active, missing from METRIC
select r.metric_code, r.metric_label, r.data_status_code, r.is_active
from reference.catalog.metric_raw as r
left join reference.catalog.metric as m
    on m.metric_code = r.metric_code
where upper(trim(to_varchar(r.is_active))) in ('TRUE', '1', 'T')
    and lower(trim(to_varchar(r.data_status_code))) = 'active'
    and m.metric_code is null;

-- -----------------------------------------------------------------------------
-- 12–15 Cross-table consistency
-- -----------------------------------------------------------------------------

-- 12) METRIC is_derived = TRUE with no wiring in METRIC_DERIVED_INPUT (as input) nor as METRIC_DERIVED.primary_metric_code
--     (tighten/loosen OR logic per CATALOG_METRIC_DERIVED_LAYOUT.md ownership)
select m.metric_code, m.metric_label, m.is_derived
from reference.catalog.metric as m
where coalesce(m.is_derived::boolean, false) = true
    and not exists (
        select 1
        from reference.catalog.metric_derived_input as mdi
        where mdi.input_metric_code = m.metric_code
    )
    and not exists (
        select 1
        from reference.catalog.metric_derived as md
        where md.primary_metric_code = m.metric_code
    );

-- 13) METRIC_DERIVED: analytics_layer_code = 'model' but model_type_code null/empty
select md.metric_derived_code, md.analytics_layer_code, md.model_type_code
from reference.catalog.metric_derived as md
where lower(trim(to_varchar(md.analytics_layer_code))) = 'model'
    and (
        md.model_type_code is null
        or trim(to_varchar(md.model_type_code)) = ''
    );

-- 14) METRIC_DERIVED: analytics_layer_code = 'estimate' but estimate_type_code null/empty
select md.metric_derived_code, md.analytics_layer_code, md.estimate_type_code
from reference.catalog.metric_derived as md
where lower(trim(to_varchar(md.analytics_layer_code))) = 'estimate'
    and (
        md.estimate_type_code is null
        or trim(to_varchar(md.estimate_type_code)) = ''
    );

-- 15) METRIC references CONCEPT where concept.is_active is false
select m.metric_code, m.concept_code, c.is_active as concept_is_active
from reference.catalog.metric as m
inner join reference.catalog.concept as c
    on c.concept_code = m.concept_code
where coalesce(c.is_active::boolean, false) = false;

-- -----------------------------------------------------------------------------
-- 16–18 Coverage and freshness
-- -----------------------------------------------------------------------------

-- 16) Active metrics per geo_level_code; flag levels with < 5 active metrics
with cnt as (
    select
        m.geo_level_code,
        count(*) as n_active_metrics
    from reference.catalog.metric as m
    where upper(trim(to_varchar(m.is_active))) in ('TRUE', '1', 'T')
    group by 1
)
select
    g.geo_level_code,
    coalesce(c.n_active_metrics, 0) as n_active_metrics
from reference.catalog.geo_level as g
left join cnt as c
    on c.geo_level_code = g.geo_level_code
qualify coalesce(c.n_active_metrics, 0) < 5
order by n_active_metrics asc, g.geo_level_code;

-- Full distribution (remove QUALIFY / use separate query):
-- select geo_level_code, count(*) from reference.catalog.metric where ... group by 1 order by 2 desc;

-- 17a) REPO SEMANTIC: active datasets whose **data_status_code** is not 'active' (lifecycle)
select
    d.vendor_code,
    count(*) as n_datasets_not_data_active
from reference.catalog.dataset as d
where upper(trim(to_varchar(d.is_active))) in ('TRUE', '1', 'T')
    and lower(trim(to_varchar(d.data_status_code))) <> 'active'
group by 1
order by n_datasets_not_data_active desc;

-- 17b) LITERAL (if you meant **pipeline_status** ≠ literal 'active' — rarely true in this catalog)
select
    d.vendor_code,
    count(*) as n_datasets_pipeline_not_string_active
from reference.catalog.dataset as d
where upper(trim(to_varchar(d.is_active))) in ('TRUE', '1', 'T')
    and lower(trim(to_varchar(d.pipeline_status))) <> 'active'
group by 1
order by n_datasets_pipeline_not_string_active desc;

-- 18) Vendors that have ≥1 active dataset but vendor.contract_status is expired or null/blank
select
    v.vendor_code,
    v.contract_status,
    count(distinct d.dataset_code) as n_active_datasets
from reference.catalog.vendor as v
inner join reference.catalog.dataset as d
    on d.vendor_code = v.vendor_code
where upper(trim(to_varchar(d.is_active))) in ('TRUE', '1', 'T')
group by v.vendor_code, v.contract_status
having lower(trim(to_varchar(v.contract_status))) = 'expired'
    or v.contract_status is null
    or trim(to_varchar(v.contract_status)) = ''
order by v.vendor_code, v.contract_status;

-- -----------------------------------------------------------------------------
-- 19–20 Structural sanity
-- -----------------------------------------------------------------------------

-- 19) Duplicate metric_code in METRIC
select m.metric_code, count(*) as n
from reference.catalog.metric as m
group by 1
having count(*) > 1;

-- 20) GEO_LEVEL codes referenced by METRIC but missing from GEO_LEVEL (same as Q2; kept for checklist parity)
select distinct m.geo_level_code
from reference.catalog.metric as m
where m.geo_level_code is not null
    and trim(to_varchar(m.geo_level_code)) <> ''
minus
select g.geo_level_code
from reference.catalog.geo_level as g;
