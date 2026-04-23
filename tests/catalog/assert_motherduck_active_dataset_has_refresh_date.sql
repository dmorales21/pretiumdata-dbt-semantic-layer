{{ config(tags=["catalog_hard_gate"]) }}
-- Q7 — MotherDuck-served and active DATASET must have last_refresh_date (catalog_health_inventory §7).
-- If this returns rows after `dataset.csv` was fixed in git, Snowflake still has a stale seed load:
--   dbt seed --full-refresh --select dataset
select
    d.dataset_code
from {{ ref('dataset') }} as d
where upper(trim(to_varchar(d.is_active))) in ('TRUE', '1', 'T')
    and upper(trim(to_varchar(d.is_motherduck_served))) in ('TRUE', '1', 'T')
    and (
        d.last_refresh_date is null
        or trim(to_varchar(d.last_refresh_date)) = ''
    )
