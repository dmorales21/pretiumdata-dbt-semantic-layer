# Funnel Data Transformation – Data Science & Analytics Guide

**Audience:** Data scientists, analysts, analytics engineers  
**Last updated:** February 2026  
**Companion:** [FUNNEL_DATA_TRANSFORMATION_BUSINESS.md](FUNNEL_DATA_TRANSFORMATION_BUSINESS.md) (business / Power BI), [DS_FUNNEL_BH_VIEWS_INVENTORY.md](DS_FUNNEL_BH_VIEWS_INVENTORY.md) (source inventory)

---

## 1. Where to Query

| Use case | Object | Grain | Format |
|----------|--------|--------|--------|
| **Dashboards / Power BI** | `EDW_PROD.DELIVERY.V_FUNNEL_CONVERSION_POWER_BI` | One row per (date_reference, geo_id) | Wide: one column per metric |
| **Time series / multi-metric analysis** | `EDW_PROD.MART.mart_funnel_conversion_metrics` | One row per (date_reference, geo_id, metric_id) | Long: metric_id + value |
| **Source of truth / lineage** | `TRANSFORM_PROD.FACT.fact_funnel_conversion_metrics_ts` | Same as mart (long) | Long with domain/taxon/vendor |

**Recommendation:** Use **mart (long)** for modeling, forecasting, or joining to other EDW tables; use **delivery (wide)** for reporting and Power BI.

---

## 2. Grain and Keys

- **Primary grain:** `(date_reference, geo_id)`.
- **date_reference:** DATE; day the metrics are measured for (lead/appointment/lease event date).
- **geo_id:** VARCHAR; community or building identifier from Funnel (PMS_COMMUNITY_ID or COMPANY_ID). Not yet mapped to CBSA or portfolio; use for community-level analysis.
- **geo_level_code:** Typically `'METRIC'`; reserved for future hierarchy.
- **Mart long:** Add **metric_id** as the third dimension; one row per (date_reference, geo_id, metric_id) with a single **value**.

---

## 3. Metric Catalog (Mart Long)

All metrics in the mart share **domain = 'HOUSING'**, **taxon = 'HOU_DEMAND'**, **vendor_name = 'FUNNEL'**.

| metric_id | unit | Description | Denominator note |
|-----------|------|-------------|------------------|
| `FUNNEL_LEAD_TO_APPT_CONVERSION_PCT` | PCT | (Appointments scheduled ÷ New leads) × 100 | NULL when new_leads = 0 |
| `FUNNEL_APPT_TO_TOUR_CONVERSION_PCT` | PCT | (Tours completed ÷ Appointments scheduled) × 100 | NULL when appointments_scheduled = 0 |
| `FUNNEL_TOUR_TO_APPLICATION_CONVERSION_PCT` | PCT | (Applications submitted ÷ Tours completed) × 100 | NULL when appointments_completed = 0 |
| `FUNNEL_LEAD_TO_LEASE_CONVERSION_PCT` | PCT | (Rented ÷ New leads) × 100 | NULL when new_leads = 0 |
| `FUNNEL_PRE_TOUR_FOLLOW_UP_PCT` | PCT | % leads with follow-up before tour | **Placeholder:** NULL until CLIENT_TOUCHES logic added |
| `FUNNEL_POST_TOUR_FOLLOW_UP_PCT` | PCT | % tours with follow-up after | **Placeholder:** NULL until CLIENT_TOUCHES logic added |
| `FUNNEL_LAST_90D_QUEUE_CNT` | COUNT | Rolling 90-day count of new leads by community | Sum of new_leads over last 90 days |
| `FUNNEL_NO_SHOW_PCT` | PCT | No-show % of scheduled appointments | From CLIENT_APPOINTMENTS (status 60) |
| `FUNNEL_TOUR_COMPLETED_PCT` | PCT | Tour completed % of scheduled appointments | From CLIENT_APPOINTMENTS (status 50) |

**Value constraints:** PCT metrics are between 0 and 100 (or NULL). COUNT metrics are non-negative. Rows with invalid/out-of-range values are filtered out in the fact layer.

---

## 4. Lineage and Upstream

```
DS_FUNNEL_BH.STANDARD.CLIENT_FUNNEL
DS_FUNNEL_BH.STANDARD.CLIENT_APPOINTMENTS
DS_FUNNEL_BH.STANDARD.LEASE_TRANSACTION_HISTORY
        ↓
TRANSFORM_PROD.FACT.housing_hou_demand_funnel_bh   (daily counts by community)
TRANSFORM_PROD.FACT.fact_funnel_appointment_outcomes_daily (no_show_pct, tour_completed_pct)
        ↓
TRANSFORM_PROD.FACT.fact_funnel_conversion_metrics_ts (conversion %, last_90d queue, no_show/tour_completed)
        ↓
EDW_PROD.MART.mart_funnel_conversion_metrics (long)
EDW_PROD.DELIVERY.v_funnel_conversion_power_bi (wide)
```

- **CLIENT_FUNNEL:** NEW_LEAD, IS_APPOINTMENT_SCHEDULED, IS_APPOINTMENT_COMPLETED, IS_APPLICATION_SUBMITTED, IS_RENTED; keyed by LEAD_CREATED_AT and PMS_COMMUNITY_ID/COMPANY_ID.
- **CLIENT_APPOINTMENTS:** APPOINTMENT_START, APPOINTMENT_STATUS (object with id: 50 = Completed, 60 = No Show), GROUP_ID, COMPANY_ID.
- **LEASE_TRANSACTION_HISTORY:** EVENT_TIME, COMMUNITY_ID, COMPANY_ID (lease events).

### Variant / alternative data types (JSON and OBJECT)

The share may expose some columns as **OBJECT** (VARIANT) or **VARCHAR** (JSON strings). The funnel fact layer handles these explicitly:

- **CLIENT_APPOINTMENTS – status:** The appointment status is parsed in `fact_funnel_appointment_outcomes_daily` via the `funnel_parse_appointment_status` macro so that all of the following are supported:
  - **INTEGER column** (e.g. `STATUS`): value used directly as status code.
  - **OBJECT (VARIANT)** (e.g. `APPOINTMENT_STATUS` with `{"id": 50}`): `id` is extracted with `GET(..., 'id')`.
  - **VARCHAR JSON string** (e.g. `'{"id": 50}'`): parsed with `TRY_PARSE_JSON` then `GET(..., 'id')`.
  Column name is configurable via `dbt_project.yml` vars: `funnel_appointment_status_column` (default `APPOINTMENT_STATUS`), and `funnel_appointment_date_column` for the date column. Run discovery if the build fails with an invalid identifier.

- **LISTING_HISTORY_DAILY – LAYOUT_TYPE, UNIT_STATUS:** These are OBJECT (Variant/JSON) in the share. **fact_funnel_listing_history** parses them via the `funnel_variant_get` macro and exposes **layout_type_id**, **layout_type_name**, **unit_status_id**, **unit_status_name** (keys `id` and `name`; handles OBJECT or VARCHAR JSON). **housing_hou_inventory_funnel_bh** aggregates by date/building only; use the listing history fact for status or layout breakdowns.

**Full variant audit:** To ensure all OBJECT columns across all 57 funnel views are accounted for, run `scripts/discovery/list_funnel_object_columns.py`, save the output to `docs/vendors/funnel_bh/discovery/OBJECT_COLUMNS_INVENTORY.txt`, and follow the checklist in [FUNNEL_VARIANT_COLUMNS_INVENTORY.md](FUNNEL_VARIANT_COLUMNS_INVENTORY.md).

---

## 5. Joining to Other Data

- **By geography:** Use **geo_id** to join to property/community dimensions. geo_id is not yet standardized to a canonical property ID; it is the Funnel community or company identifier.
- **By date:** Use **date_reference** (DATE). Data is daily; no time-of-day.
- **By domain/taxon:** Filter `domain = 'HOUSING'` and `taxon = 'HOU_DEMAND'` when combining with other EDW marts that use the same taxonomy.

---

## 6. Data Quality and Caveats

- **NULL conversion rates:** Conversion PCT is NULL when the denominator (e.g. new_leads, appointments_scheduled) is 0. This avoids division by zero; treat as “no activity” for that day/community.
- **Pre-Tour / Post-Tour follow up %:** Always NULL until CLIENT_TOUCHES is wired; column exists for future use.
- **Last 90d queue:** Rolling window is 89 PRECEDING + CURRENT ROW (90 rows). Early dates in the series have fewer than 90 days of history; interpret first ~90 days per community with care.
- **No-show and tour completed %:** Sourced from CLIENT_APPOINTMENTS; status is parsed from the configured status column (see *Variant / alternative data types* above) so OBJECT, VARCHAR JSON, or integer are all supported. 50 = Completed, 60 = No Show. Scheduled count is all appointments with a non-null date; completed/no_show are subsets.

---

## 7. Time Series and Rolling Metrics

- **last_90d_queue_count:** Implemented as `SUM(new_leads) OVER (PARTITION BY geo_id ORDER BY date_reference ROWS BETWEEN 89 PRECEDING AND CURRENT ROW)`. Use for “queue” or pipeline depth by community.
- For custom rolling windows, query the **mart (long)**, filter `metric_id = 'FUNNEL_NEW_LEADS_DAILY'` from the upstream demand model if needed, or use the pre-aggregated FUNNEL_LAST_90D_QUEUE_CNT.

---

## 8. Mart Long: Column Reference

| Column | Type | Description |
|--------|------|-------------|
| date_reference | DATE | Report date |
| geo_id | VARCHAR | Community/building ID |
| geo_level_code | VARCHAR | Level (e.g. METRIC) |
| ID_CBSA | VARCHAR | Reserved; often NULL |
| metric_id | VARCHAR | Metric identifier (see §3) |
| value | FLOAT | Metric value |
| unit | VARCHAR | PCT or COUNT |
| frequency | VARCHAR | DAILY |
| domain | VARCHAR | HOUSING |
| taxon | VARCHAR | HOU_DEMAND |
| vendor_name | VARCHAR | FUNNEL |
| source_system | VARCHAR | DS_FUNNEL_BH |
| meta_source | VARCHAR | DS_FUNNEL_BH |
| meta_dataset | VARCHAR | CLIENT_FUNNEL |
| created_at | TIMESTAMP_NTZ | Record creation time |

---

## 9. Future: Pre-Tour and Post-Tour Follow Up %

Planned source: **CLIENT_TOUCHES**. Once available:

- **Pre-Tour follow up %:** Logic will classify touches before a lead’s first appointment and compute % of leads with at least one such touch.
- **Post-Tour follow up %:** Logic will classify touches after an appointment and compute % of tours with at least one such touch.

Discovery and column mapping: [discovery/README.md](discovery/README.md).

---

## 10. References

- **Business / Power BI:** [FUNNEL_DATA_TRANSFORMATION_BUSINESS.md](FUNNEL_DATA_TRANSFORMATION_BUSINESS.md)
- **Source views and cleaned models:** [DS_FUNNEL_BH_VIEWS_INVENTORY.md](DS_FUNNEL_BH_VIEWS_INVENTORY.md)
- **Funnel API (appointments):** https://developers.funnelleasing.com/api/v2/appointments.html
