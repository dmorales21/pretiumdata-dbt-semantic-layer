# Funnel Data Transformation – Business Documentation

**Audience:** Business teams, Power BI report owners, analytics consumers  
**Last updated:** February 2026  
**Status:** In production – Power BI refresh available  

**Data science / analysts:** See [FUNNEL_DATA_TRANSFORMATION_DATA_SCIENCE.md](FUNNEL_DATA_TRANSFORMATION_DATA_SCIENCE.md) for grain, metrics catalog, lineage, and joining to other data.

---

## Overview

Funnel (DS_FUNNEL_BH) leasing and lead data is transformed into **governed metrics** and published for reporting. This document describes what was built, how to use it in Power BI, and what each metric means.

---

## Quick start (Power BI)

1. In Power BI, connect to **Snowflake**.
2. Use **one table** for funnel conversion:
   - **Database:** `EDW_PROD`
   - **Schema:** `DELIVERY`
   - **Table/View:** `V_FUNNEL_CONVERSION_POWER_BI`
3. Schedule dataset refresh **after** the data pipeline has run (see *Pipeline refresh* below).

**Detailed steps:** [FUNNEL_DATA_ACCESS_AND_POWER_BI.md](FUNNEL_DATA_ACCESS_AND_POWER_BI.md) – data access instructions, Power BI connection guide, and [sample_funnel_conversion_power_bi.csv](sample_funnel_conversion_power_bi.csv) for column layout and example values.

---

## What We Built

| Layer | Object | Format | Purpose |
|-------|--------|--------|---------|
| **Transform (source of truth)** | `TRANSFORM_PROD.FACT.fact_funnel_conversion_metrics_ts` | Long (date, community, metric, value) | Conversion metrics at most granular level over time |
| **Mart** | `EDW_PROD.MART.mart_funnel_conversion_metrics` | Long | Same metrics in long format for time-series and multi-metric analysis |
| **Delivery (Power BI)** | `EDW_PROD.DELIVERY.v_funnel_conversion_power_bi` | **Wide** | One row per date and community; one column per metric for easy Power BI connection |

**Grain:** One row per **date** and **community** (building/community ID). Data is at the most granular level available (not pre-aggregated to CBSA or portfolio).

---

## Connecting Power BI

1. **Data source:** Snowflake.
2. **Database / Schema / View:**
   - **Database:** `EDW_PROD`
   - **Schema:** `DELIVERY`
   - **View:** `V_FUNNEL_CONVERSION_POWER_BI`
3. **Use this view for:** Funnel conversion dashboards and the full table list for Power BI refresh (most granular metrics over time).
4. **Refresh:** Schedule your Power BI dataset refresh after the data pipeline has run (see *Pipeline refresh* below).

---

## Metrics in the Delivery View (Wide)

| Column in view | Business name | Definition | Status |
|----------------|---------------|------------|--------|
| `date_reference` | Report date | Day the metrics are measured for | ✅ Available |
| `geo_id` | Community / building | Property/community identifier (PMS community or company ID) | ✅ Available |
| `lead_to_appt_conversion_pct` | Lead to Appt conversion rate | (Appointments scheduled ÷ New leads) × 100 | ✅ Available |
| `appt_to_tour_conversion_pct` | Appt.-to-tour conversion rate | (Tours completed ÷ Appointments scheduled) × 100. *Tour = appointment completed.* | ✅ Available |
| `tour_to_application_conversion_pct` | Tour-to-application conversion | (Applications submitted ÷ Tours completed) × 100 | ✅ Available |
| `lead_to_lease_conversion_pct` | Lead-to-lease conversion rate | (Rented ÷ New leads) × 100 | ✅ Available |
| `pre_tour_follow_up_pct` | Pre-Tour follow up % | % of leads with follow-up before tour | 🔜 Source: **CLIENT_TOUCHES**. Run discovery (see `docs/vendors/funnel_bh/discovery/README.md`) and add logic; until then NULL. |
| `post_tour_follow_up_pct` | Post-Tour follow up % | % of tours with follow-up after | 🔜 Source: **CLIENT_TOUCHES**. Run discovery and add touch-after-tour logic; until then NULL. |
| `last_90d_queue_count` | Last 90 day queue count | Rolling 90-day count of new leads by community | ✅ **CLIENT_FUNNEL** (implemented) |
| `no_show_pct` | No show % | No-show % (of scheduled appointments) | ✅ **CLIENT_APPOINTMENTS** (APPOINTMENT_STATUS.id = 60); wired to share. |
| `tour_completed_pct` | Tour completed % | Tour completed % (of scheduled appointments) | ✅ **CLIENT_APPOINTMENTS** (APPOINTMENT_STATUS.id = 50); wired to share. |
| `refreshed_at` | Refreshed at | When the view was last refreshed | ✅ Available |

**Available** = populated from DS_FUNNEL_BH (CLIENT_FUNNEL, CLIENT_APPOINTMENTS).  
**Placeholder** = column exists; Pre/Post-Tour follow up % require CLIENT_TOUCHES discovery and logic (see discovery/README.md).

### Interpreting the numbers

- **Conversion % (lead→appt, appt→tour, etc.):** Shown as a percentage (0–100). If there were no leads or no appointments on that day for that community, the rate can be **blank (NULL)** — that means “no activity,” not missing data.
- **Last 90 day queue count:** Rolling count of new leads over the past 90 days for that community. Use it to see pipeline depth.
- **No show % / Tour completed %:** Of all scheduled appointments for that day and community, what % were no-shows and what % were completed (tours). They can sum to less than 100% because other statuses (e.g. cancelled, tentative) are not included in these two rates.
- **Pre-Tour follow up % / Post-Tour follow up %:** Columns are present but **empty** until we add the source (CLIENT_TOUCHES). You can already build reports; these columns will populate later.

---

## Full table list for Power BI refresh

For the **full table list** and scheduled refresh, use this single object:

| Database | Schema | View / Table |
|----------|--------|----------------|
| EDW_PROD | DELIVERY | V_FUNNEL_CONVERSION_POWER_BI |

No other tables are required for funnel conversion metrics in Power BI.

---

## Data Flow (Transformation Pipeline)

```
DS_FUNNEL_BH (Snowflake share)
    ↓
CLIENT_FUNNEL (leads, appointments, applications, rented)
    ↓
housing_hou_demand_funnel_bh (daily counts by community)
    ↓
fact_funnel_conversion_metrics_ts (conversion % and counts)
    ↓
EDW_PROD.MART.mart_funnel_conversion_metrics (long)
EDW_PROD.DELIVERY.v_funnel_conversion_power_bi (wide)  ← Use for Power BI
```

- **Source:** Funnel application data in `DS_FUNNEL_BH` (CLIENT_FUNNEL view).
- **Governance:** All funnel metrics are tagged with domain (HOUSING), taxon (HOU_DEMAND), and vendor (FUNNEL). Quality and lineage are applied at the fact and all_ts layers.
- **Canonical:** Data lives in canonical schemas only (TRANSFORM_PROD.FACT, EDW_PROD.MART, EDW_PROD.DELIVERY). No ad-hoc or non-canonical tables.

---

## Pipeline Refresh

For Power BI to show up-to-date funnel conversion metrics, the pipeline must run first:

1. **dbt models run** (Data Engineering / scheduled job):
   - `housing_hou_demand_funnel_bh` (demand counts from Funnel)
   - `fact_funnel_conversion_metrics_ts` (conversion metrics)
   - `mart_funnel_conversion_metrics` (mart long)
   - `v_funnel_conversion_power_bi` (delivery wide)

2. **Power BI refresh** (scheduled or manual):
   - Connect to `EDW_PROD.DELIVERY.V_FUNNEL_CONVERSION_POWER_BI` and refresh the dataset.

If you need a different refresh cadence or the full table list for your Power BI refresh, coordinate with Data Engineering so the dbt run and Power BI schedule stay aligned.

---

## Long Format (Mart) – Optional

If you need **one row per metric** (e.g. for time-series charts or multi-metric reports), use the mart view instead of the delivery view:

- **View:** `EDW_PROD.MART.mart_funnel_conversion_metrics`
- **Columns:** `date_reference`, `geo_id`, `metric_id`, `value`, `unit`, `domain`, `taxon`, `vendor_name`, `source_system`, `meta_source`, `meta_dataset`, `created_at`
- **Use case:** Pivot by `metric_id` (e.g. FUNNEL_LEAD_TO_APPT_CONVERSION_PCT, FUNNEL_APPT_TO_TOUR_CONVERSION_PCT, …) and `date_reference` for trends.

---

## Future Metrics (Placeholders)

The following will be filled once source data and definitions are confirmed with the business and Data Engineering:

| Metric | Likely source | Next step |
|--------|----------------|-----------|
| Pre-Tour follow up % | CLIENT_TOUCHES (touch before first appointment) | Run discovery (discovery/README.md); add logic. Currently NULL |
| Post-Tour follow up % | CLIENT_TOUCHES + appointment date | Run discovery (discovery/README.md); add logic. Currently NULL |
| Last 90 day queue count | CLIENT_FUNNEL + date window; “queue” definition | Implemented (rolling 90d new leads) |
| No show % / Tour completed % | CLIENT_APPOINTMENTS (status: no_show vs completed) | Implemented via fact_funnel_appointment_outcomes_daily. Run discovery if build fails |

---

## Questions or Issues

- **Data or metrics:** Contact Data Engineering or the data product owner for Funnel.
- **Technical pipeline:** See [DS_FUNNEL_BH_VIEWS_INVENTORY.md](DS_FUNNEL_BH_VIEWS_INVENTORY.md) for run order, validation, and canonical compliance.
- **Power BI connection or refresh:** Use **EDW_PROD.DELIVERY.V_FUNNEL_CONVERSION_POWER_BI** as the single table for the funnel conversion full table list and refresh.
- **Analysts / data science:** See [FUNNEL_DATA_TRANSFORMATION_DATA_SCIENCE.md](FUNNEL_DATA_TRANSFORMATION_DATA_SCIENCE.md) for grain, metric catalog, lineage, and joining to other datasets.

### Troubleshooting

| Issue | What to check |
|-------|----------------|
| No data or old data in Power BI | Ensure the dbt pipeline has run (see *Pipeline refresh*). Then refresh the Power BI dataset. |
| Conversion rates are blank for some dates/communities | Expected when there were no leads or appointments (denominator is 0). |
| Pre-Tour or Post-Tour follow up always blank | These are not yet populated; they will be added when CLIENT_TOUCHES is wired. |
| Need one row per metric for charts | Use **EDW_PROD.MART.mart_funnel_conversion_metrics** (long format) instead of the delivery view; see *Long Format (Mart)* above. |
