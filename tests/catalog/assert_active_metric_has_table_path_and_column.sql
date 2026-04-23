{{ config(tags=["catalog_hard_gate"]) }}
-- Q6 — active METRIC must have table_path and snowflake_column (catalog_health_inventory §6).
select
    m.metric_code,
    m.metric_label
from {{ ref('metric') }} as m
where upper(trim(to_varchar(m.is_active))) in ('TRUE', '1', 'T')
    and (
        m.table_path is null
        or trim(to_varchar(m.table_path)) = ''
        or m.snowflake_column is null
        or trim(to_varchar(m.snowflake_column)) = ''
    )
