{{ config(tags=["catalog_hard_gate"]) }}
-- Q19 — duplicate metric_code in METRIC (catalog_health_inventory §19).
select
    m.metric_code,
    count(*) as ct
from {{ ref('metric') }} as m
group by m.metric_code
having count(*) > 1
