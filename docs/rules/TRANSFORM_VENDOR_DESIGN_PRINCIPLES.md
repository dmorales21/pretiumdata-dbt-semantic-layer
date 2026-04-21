# TRANSFORM.[VENDOR] Model Design Principles
# Applies to: all FACT_ models in TRANSFORM.DEV reading from TRANSFORM.[VENDOR]

---

## 1. Source fidelity first, enrichment second

Read vendor tables as-is. Do not clean, impute, or cast in the same CTE that joins to
geography. Separate raw selection from enrichment — it makes failures obvious.

```sql
with source as (
    select * from {{ source('cherre', 'tax_assessor_v2') }}
),
geo as (
    select * from REFERENCE.GEOGRAPHY.COUNTY_CBSA_XWALK
)
select
    s.cherre_parcel_id,
    s.fips_code                    as county_fips,
    g.cbsa_code                    as cbsa_id,
    g.cbsa_name,
    cast(s.assessed_value_total as float) as assessed_value_total,
    ...
from source s
left join geo g on s.fips_code = g.county_fips
```

---

## 2. Always populate census geo keys

Every FACT_ model with a geographic dimension must output these columns where applicable:

| Column | Type | Source |
|--------|------|--------|
| `county_fips` | TEXT(5) | vendor FIPS or COUNTY_CBSA_XWALK |
| `cbsa_id` | TEXT(5) | COUNTY_CBSA_XWALK or ZCTA_CBSA_XWALK |
| `cbsa_name` | TEXT | same xwalk |
| `state_fips` | TEXT(2) | LEFT(county_fips, 2) |
| `geo_level_code` | TEXT | normalized vocabulary (see §4) |

Null CBSA is acceptable for rural counties with no CBSA assignment. CBSA populated
rate must exceed 80% at the target grain to pass metric registration gate 1.

---

## 3. Type-check at the boundary

Vendor columns are frequently wrong types. Fix at source selection, not mid-join.

Known traps:
- `MARKERR.CRIME_LATEST.ZIPCODE` → FLOAT → `LPAD(CAST(ZIPCODE::INT AS TEXT), 5, '0')`
- `MARKERR.RENT_PROPERTY_CBSA_MONTHLY.CBSA_ID` → NUMBER → `CAST(CBSA_ID AS TEXT)`
- `REDFIN.*` metrics → all TEXT → `TRY_CAST(MEDIAN_SALE_PRICE AS FLOAT)`
- `BPS.PERMITS_COUNTY.VALUE` → NUMBER, but tall — unpivot before exposing as metrics

---

## 4. Normalize geo_level_code

Vendor-specific grain labels must be mapped to the canonical vocabulary before the model
materializes. Never pass vendor strings downstream.

| Vendor term | Canonical value |
|-------------|----------------|
| metro, msa, cbsa | `cbsa` |
| county | `county` |
| zip, zipcode, zcta | `zip` |
| state | `state` |
| national | `national` |
| city, neighborhood, blockgroup | **exclude** — no compliant census spine |

---

## 5. Tall > wide at the FACT layer

Vendors deliver wide tables. FACT_ models should pivot to long format
(one row per geo × date × metric) unless the downstream use case explicitly requires wide.

Benefits: uniform metric registration, single dbt test pattern, downstream aggregation
is a filter not a reshape.

```sql
-- preferred tall pattern
unpivot(metric_value for metric_name in (
    vacancy_rate, occupancy_rate, market_asking_rent_per_unit, ...
))
```

---

## 6. One temporal grain per model

Pick one and stay consistent. Do not mix monthly and quarterly rows in the same FACT
model. If the vendor delivers both, build two models.

Date column naming convention:
- Monthly → `date_month` (DATE, first of month)
- Quarterly → `date_quarter` (DATE, first of quarter)
- Snapshot → `snapshot_date` (DATE, as-of date)

---

## 7. Vendor-specific join keys stay in TRANSFORM.DEV

Crosswalk tables (`REF_ZILLOW_COUNTY_TO_FIPS`, `REF_ZILLOW_METRO_TO_CBSA`, etc.) are
seeds in `TRANSFORM.DEV`. They are never promoted to `REFERENCE.GEOGRAPHY` — that schema
is census spine only. Vendor xwalks move to `TRANSFORM.[VENDOR]` when Jon promotes them.

---

## 8. Materialization strategy

| Model type | Materialization | Reason |
|------------|----------------|--------|
| FACT_ (large time series) | `incremental` | avoid full refresh on 100M+ row tables |
| FACT_ (small/static) | `table` | simpler, full-refresh acceptable |
| REF_ seeds | `seed` | CSV-controlled, version-tracked |

Incremental strategy: `unique_key = [geo_id, date_column, metric_name]`
`on_schema_change = 'append_new_columns'`

---

## 9. Fail loudly on geo compliance

Add a singular test in `tests/` that asserts cbsa_id coverage ≥ 80% per model.
A model that silently ships with 20% CBSA fill is worse than a model that fails CI.

```sql
-- tests/assert_cbsa_coverage_fact_zillow_home_values.sql
select count_if(cbsa_id is null) / count(*) as null_rate
from {{ ref('fact_zillow_home_values') }}
where geo_level_code = 'cbsa'
having null_rate > 0.20
```
