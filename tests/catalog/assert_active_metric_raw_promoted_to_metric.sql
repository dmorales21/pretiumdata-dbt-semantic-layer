{{ config(tags=["catalog_hard_gate"]) }}
-- Q11 — Built **metric** must contain every **metric_raw** row that is both active in the catalog
-- (`is_active`) and active in governance (`data_status_code = active`). Backlog rows stay in
-- **metric_raw** only with `is_active = FALSE` and/or a non-active status until promoted.
select
    r.metric_code
from {{ ref('metric_raw') }} as r
left join {{ ref('metric') }} as m
    on m.metric_code = r.metric_code
where upper(trim(to_varchar(r.is_active))) in ('TRUE', '1', 'T')
    and lower(trim(to_varchar(r.data_status_code))) = 'active'
    and m.metric_code is null
