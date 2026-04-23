# DS_FUNNEL_BH – Views inventory and cleaned-model mapping

**Source:** Discovery run 2026-02-09 (Python Snowflake connector).  
**Database:** `DS_FUNNEL_BH`  
**Application schemas:** `STANDARD` (primary), `DBT_CGENTRY`, `DBT_PROSPERO`.  
**Excluded:** `INFORMATION_SCHEMA` (Snowflake system views).

**Documentation:**  
- [FUNNEL_DATA_TRANSFORMATION_BUSINESS.md](FUNNEL_DATA_TRANSFORMATION_BUSINESS.md) – Power BI connection, metric definitions, and pipeline refresh for business teams.  
- [FUNNEL_DATA_TRANSFORMATION_DATA_SCIENCE.md](FUNNEL_DATA_TRANSFORMATION_DATA_SCIENCE.md) – Data science and analytics: grain, metric catalog, lineage, joining, and data quality.  
- [FUNNEL_VARIANT_COLUMNS_INVENTORY.md](FUNNEL_VARIANT_COLUMNS_INVENTORY.md) – OBJECT (Variant/JSON) columns: discovery script, extraction status, and checklist.

Every view below must have a **cleaned model** in `TRANSFORM_PROD.CLEANED` that preserves funnel data columns (one cleaned model per view).

---

## Schemas in DS_FUNNEL_BH

| Schema             | Purpose                          |
|--------------------|----------------------------------|
| STANDARD           | Primary application views (use this for sources) |
| DBT_CGENTRY        | Alternate / dbt export schema    |
| DBT_PROSPERO       | Alternate (subset of views)      |
| INFORMATION_SCHEMA | Snowflake system (do not clean)  |

---

## All application views (STANDARD) → cleaned model target

| # | Source view (DS_FUNNEL_BH.STANDARD) | Cleaned model (transform_prod/cleaned/) |
|---|--------------------------------------|----------------------------------------|
| 1 | ACCOUNT_GROUPS | funnel_account_groups |
| 2 | ACTION_REQUIRED | funnel_action_required |
| 3 | AGENT_ASSIGNMENT | funnel_agent_assignment |
| 4 | AGENT_GROUP_HOURS | funnel_agent_group_hours |
| 5 | AMENITY_RESERVATION | funnel_amenity_reservation |
| 6 | APPLICANTS | funnel_applicants |
| 7 | APPLICANT_HISTORY | funnel_applicant_history |
| 8 | APPOINTMENTS_AGENTAVAILABILITYBLOCK | funnel_appointments_agentavailabilityblock |
| 9 | AUTH_USERS | funnel_auth_users |
| 10 | BULKMESSAGES | funnel_bulkmessages |
| 11 | CHATBOT_CONVERSATIONS | funnel_chatbot_conversations |
| 12 | CLIENTS | funnel_clients |
| 13 | CLIENTS_PERSON | funnel_clients_person |
| 14 | CLIENT_APPOINTMENTS | funnel_client_appointments |
| 15 | CLIENT_FUNNEL | funnel_client_funnel |
| 16 | CLIENT_HISTORY | funnel_client_history |
| 17 | CLIENT_QUOTES | funnel_client_quotes |
| 18 | CLIENT_REMINDERS | funnel_client_reminders |
| 19 | CLIENT_TOUCHES | funnel_client_touches |
| 20 | CONCESSIONS | funnel_concessions |
| 21 | CONVERSATIONS | funnel_conversations |
| 22 | GROUP_ASSIGNMENTS | funnel_group_assignments |
| 23 | INTEGRATION_AGENTS | funnel_integration_agents |
| 24 | LEADACQUISITION_COST | funnel_leadacquisition_cost |
| 25 | LEAD_ACQUISITION_COST | funnel_lead_acquisition_cost |
| 26 | LEASE_TRANSACTION_HISTORY | funnel_lease_transaction_history |
| 27 | LISTING_HISTORY_DAILY | funnel_listing_history_daily |
| 28 | LISTING_HISTORY_PERIODS | funnel_listing_history_periods |
| 29 | MERGED_CLIENTS | funnel_merged_clients |
| 30 | ONLINELEASING_APPLICATION | funnel_onlineleasing_application |
| 31 | ONLINELEASING_DEATHINUNITNOTICE | funnel_onlineleasing_deathinunitnotice |
| 32 | ONLINELEASING_HOLDOVER | funnel_onlineleasing_holdover |
| 33 | ONLINELEASING_LEASE | funnel_onlineleasing_lease |
| 34 | ONLINELEASING_LEASEOFFER | funnel_onlineleasing_leaseoffer |
| 35 | ONLINELEASING_LEASEPERSON | funnel_onlineleasing_leaseperson |
| 36 | ONLINELEASING_MIDLEASECHANGE | funnel_onlineleasing_midleasechange |
| 37 | ONLINELEASING_RECONCILIATION | funnel_onlineleasing_reconciliation |
| 38 | ONLINELEASING_RENEWAL | funnel_onlineleasing_renewal |
| 39 | ONLINELEASING_RENTALOPTIONITEMS | funnel_onlineleasing_rentaloptionitems |
| 40 | ONLINELEASING_TRANSFER | funnel_onlineleasing_transfer |
| 41 | ONLINELEASING_VACATE | funnel_onlineleasing_vacate |
| 42 | ONLINELEASING_WARNING | funnel_onlineleasing_warning |
| 43 | PUSHED_CLIENTS | funnel_pushed_clients |
| 44 | PUSHED_PEOPLE | funnel_pushed_people |
| 45 | RESAPP_LEASEPERSON | funnel_resapp_leaseperson |
| 46 | RESAPP_MESSAGES | funnel_resapp_messages |
| 47 | STRIPE_BALANCE_TRANSACTIONS | funnel_stripe_balance_transactions |
| 48 | STRIPE_CHARGES | funnel_stripe_charges |
| 49 | STRIPE_DISPUTES | funnel_stripe_disputes |
| 50 | STRIPE_REFUNDS | funnel_stripe_refunds |
| 51 | TWILIO_EMAILS | funnel_twilio_emails |
| 52 | TWILIO_LIVECHAT | funnel_twilio_livechat |
| 53 | TWILIO_PHONECALLS | funnel_twilio_phonecalls |
| 54 | TWILIO_SMS | funnel_twilio_sms |
| 55 | TWILIO_WORKER_EVENTS | funnel_twilio_worker_events |
| 56 | UNITS | funnel_units |
| 57 | UNMANAGED_LEADS | funnel_unmanaged_leads |

**Total: 57 application views** (excluding INFORMATION_SCHEMA). There are **0 tables** in the share; all are views.

---

## sources.yml configuration

Set the funnel source to:

- **database:** `DS_FUNNEL_BH`
- **schema:** `STANDARD`

Then add a `tables` (or `views`) entry for each view name above so dbt can reference them via `source('funnel', 'VIEW_NAME')`.

---

## LISTING_HISTORY_DAILY column schema

Discovered via `scripts/discovery/list_funnel_listing_history_columns.py` (run with Snowflake env vars + `.venv/bin/python`).

| # | Column       | Type   | Notes |
|---|--------------|--------|-------|
| 1 | ID           | TEXT   | |
| 2 | COMPANY_ID   | NUMBER | |
| 3 | DATE_DAY     | DATE   | |
| 4 | LAYOUT_TYPE  | OBJECT | Variant/JSON; extracted in fact_funnel_listing_history as layout_type_id, layout_type_name (funnel_variant_get) |
| 5 | UNIT_ID      | NUMBER | |
| 6 | BUILDING_ID  | NUMBER | |
| 7 | BUILDING_NAME| TEXT   | |
| 8 | UNIT_STATUS  | OBJECT | Variant/JSON; extracted in fact_funnel_listing_history as unit_status_id, unit_status_name (funnel_variant_get) |
| 9 | SNOWFLAKE_ID | TEXT   | |
| 10| ACCOUNT_TYPE | TEXT   | Maps to ref_funnel_listing_type (e.g. rental/rentals → rentals, sale/sales → sales) |

- **No** `listing_type` or `property_type` columns; `fact_funnel_listing_history` uses **ACCOUNT_TYPE** for `ref_listing_type_name` and leaves `ref_property_type_name` NULL. **LAYOUT_TYPE** and **UNIT_STATUS** (OBJECT) are parsed in the fact layer via the `funnel_variant_get` macro (keys `id`, `name`); use columns `layout_type_id`, `layout_type_name`, `unit_status_id`, `unit_status_name`.

---

## Funnel fact layer (TRANSFORM_PROD.FACT)

| Model | Source (cleaned) | Purpose | Feeds |
|-------|------------------|---------|-------|
| fact_funnel_listing_history | funnel_listing_history_daily | Wide: listing history + ref_listing_type_name, ref_property_type_name | EDW / downstream views |
| housing_hou_inventory_funnel_bh | funnel_listing_history_daily | Long: one row per (date_reference, geo_id=BUILDING_ID, metric_id=FUNNEL_LISTING_RECORDS_DAILY), value=count | housing_hou_inventory_all_ts |
| housing_hou_demand_funnel_bh | source('funnel', 'LEASE_TRANSACTION_HISTORY'), source('funnel', 'CLIENT_FUNNEL') | Long: lease events + new leads, appointments, applications, rented by date and geo; reads from share so runs without building cleaned | housing_hou_demand_all_ts |

**Discovered columns (for reference):**
- **LEASE_TRANSACTION_HISTORY:** EVENT_TIME, COMMUNITY_ID, COMPANY_ID, TRANSACTION_TYPE, EVENT_NAME, etc. (28 cols). Demand uses EVENT_TIME::DATE, geo_id = COALESCE(COMMUNITY_ID, COMPANY_ID), metric_id = FUNNEL_LEASE_EVENTS_DAILY.
- **CLIENT_FUNNEL:** LEAD_CREATED_AT, PMS_COMMUNITY_ID, COMPANY_ID, NEW_LEAD, IS_APPOINTMENT_SCHEDULED, IS_APPOINTMENT_COMPLETED, IS_APPLICATION_SUBMITTED, IS_RENTED, etc. (30 cols). Demand uses LEAD_CREATED_AT::DATE, geo_id = PMS_COMMUNITY_ID or COMPANY_ID, metric_ids = FUNNEL_NEW_LEADS_DAILY, FUNNEL_APPOINTMENTS_SCHEDULED_DAILY, FUNNEL_APPOINTMENTS_COMPLETED_DAILY, FUNNEL_APPLICATIONS_SUBMITTED_DAILY, FUNNEL_RENTED_DAILY.

---

## Run order and all_ts requirements

- **housing_hou_inventory_all_ts**  
  Uses `incremental_strategy='append'` so dbt does not run a MERGE (avoids `invalid identifier 'DATE_REFERENCE'` when the target has different column casing). The `existing_fact_data` CTE is wrapped in `{% if is_incremental() %}` so it is never defined on full refresh (avoids reading from `{{ this }}` before the table exists). If the table was created with an older run and you still see that error, run once with `--full-refresh`.

- **housing_hou_demand_all_ts**  
  Unions `housing_hou_demand_yardi_sfdc`, `fact_housing_demand_cherre_recorder`, and `housing_hou_demand_funnel_bh`. The Yardi/SFDC view must exist in the warehouse. To run only the funnel + all_ts chain you must still build the other feeders first, e.g.:
  ```bash
  dbt run --select housing_hou_demand_yardi_sfdc housing_hou_demand_funnel_bh+
  ```
  Or run the full demand DAG so all feeders and the all_ts table are built.

## Validation (2026-02-09)

- **fact_funnel_conversion_metrics_ts, mart_funnel_conversion_metrics, v_funnel_conversion_power_bi**: `dbt run --select fact_funnel_conversion_metrics_ts mart_funnel_conversion_metrics v_funnel_conversion_power_bi` completed successfully. Feature panel reads from housing_hou_demand_funnel_bh (CLIENT_FUNNEL); mart (long) and delivery (wide) views created in EDW_PROD. IS_FINITE replaced with Snowflake-safe (value = value AND ABS(value) <= 1e308).
- **housing_hou_inventory_all_ts**: Refs verified (housing_hou_inventory_yardi, housing_hou_inventory_cherre_mls, fact_parcllabs_inventory, fact_redfin_inventory, housing_hou_inventory_funnel_bh). Source admin_catalog.dim_dataset used by multiple models. `dbt compile --select housing_hou_inventory_all_ts housing_hou_demand_all_ts` succeeds. Incremental: `existing_fact_data` only in SQL when `is_incremental()`; append strategy; final filter `date_reference > MAX(date_reference)` so only new rows inserted. Full refresh: no `existing_fact_data`, no `{{ this }}` reference; final filter `geo_id IS NOT NULL` only.
- **housing_hou_demand_all_ts**: Same pattern; `existing_fact_data` already wrapped in `is_incremental()`. Requires `housing_hou_demand_yardi_sfdc` to exist when run (include in selection or run full DAG). Tag `signal_deps` added (feeds fct_liquidity_signal, v_metric_timeseries, v_dom_timeseries_cbsa, etc.).

---

## Canonical compliance (CANONICAL_ARCHITECTURE_CONTRACT / 03_CANONICAL_PATTERNS)

| Check | Status |
|-------|--------|
| **Layer** | Fact models in `models/transform_prod/fact/` → TRANSFORM_PROD.FACT (dbt_project transform_prod.fact +schema: fact, +database: transform_prod). Funnel BH views set `database='transform_prod', schema='fact'` explicitly. |
| **Tags** | All funnel fact models include `fact`; funnel_bh views include `housing`, `inventory`/`demand`, `funnel`, `bh`, `governance`; all_ts include `quality`, `governance`; both all_ts include `signal_deps` (used by signals/EDW). |
| **Fact required columns** | date_reference, geo_id, metric_id, value, vendor_name, quality_flag present; geo_level_code (contract: geo_level); domain, taxon, meta_source, meta_dataset for lineage; completeness_pct, z_score, validation_timestamp. |
| **Long-format time series** | One row per (date_reference, geo_id, metric_id, vendor_name); VALUE, unit, frequency. |
| **Upstream** | Inventory funnel: ref(cleaned funnel_listing_history_daily). Demand funnel: source('funnel', …). all_ts: ref(feeder facts) + ref(funnel_bh) + {{ this }} when incremental. |
| **No schema sprawl** | No PUBLIC/DBT_PROJECTS_*; canonical schema names via project config and explicit database/schema on funnel views. |
| **Cleaned** | funnel_* in `transform_prod/cleaned/` with tags `cleaned`, `funnel`; database/schema cleaned; pass-through macro, no business logic. |

---

## Funnel governance (canonical)

- **Demand fact** (`housing_hou_demand_funnel_bh`): Domain HOUSING, taxon HOU_DEMAND, vendor FUNNEL; meta_source/meta_dataset for lineage (CLIENT_FUNNEL, LEASE_TRANSACTION_HISTORY). No quality_flag at view level.
- **All_ts layer** (`housing_hou_demand_all_ts`): Quality and governance applied: quality_flag, completeness_pct, z_score, validation_timestamp; access metadata from admin_catalog.dim_dataset; temporal_gap_days, geo_coverage_count, required_dimensions. Funnel rows inherit governance when unioned into all_ts.
- **Inventory**: Same pattern; `housing_hou_inventory_funnel_bh` → `housing_hou_inventory_all_ts` with governance and post-hook extract_governance_metrics.
- **Feature panel** (conversion metrics): Sourced from funnel demand counts; governed with domain/taxon/vendor and optional quality flags in `fact_funnel_conversion_metrics_ts`.

---

## Power BI metrics (feature panel → mart long → delivery wide)

Metrics requested at **most granular level over time** for Power BI refresh. Mart view = long format (one row per date, geo, metric_id, value). Delivery view = wide format (one row per date, geo; one column per metric).

| # | Metric | Definition | Source / notes |
|---|--------|------------|----------------|
| 1 | Lead to Appt conversion rate | (Appointments scheduled / New leads) × 100 | CLIENT_FUNNEL: NEW_LEAD, IS_APPOINTMENT_SCHEDULED |
| 2 | Appt.-to-tour conversion rate | (Tours completed / Appointments scheduled) × 100 | CLIENT_FUNNEL: IS_APPOINTMENT_COMPLETED / IS_APPOINTMENT_SCHEDULED (tour = appt completed) |
| 3 | Tour-to-application conversion | (Applications submitted / Tours completed) × 100 | CLIENT_FUNNEL: IS_APPLICATION_SUBMITTED / IS_APPOINTMENT_COMPLETED |
| 4 | Lead-to-lease conversion rate | (Rented / New leads) × 100 | CLIENT_FUNNEL: IS_RENTED / NEW_LEAD |
| 5 | Pre-Tour follow up % | % of leads with follow-up before tour | **Source:** CLIENT_TOUCHES. Run discovery (discovery/README.md); implement touch-before-first-appt. Currently NULL. |
| 6 | Post-Tour follow up % | % of tours with follow-up after | **Source:** CLIENT_TOUCHES. Run discovery; implement touch-after-tour. Currently NULL. |
| 7 | Last 90 day queue count | Count of leads/appts in queue (rolling 90d) | **Source:** CLIENT_FUNNEL. Implemented (rolling 90d new leads).  |
| 8 | No show % vs. Tour completed % | No-show % and Tour completed % (of scheduled appts) | **Source:** CLIENT_APPOINTMENTS. Implemented (status 50=Completed, 60=No Show). Run discovery if build fails. |

**Implementation**: Feature panel = `fact_funnel_conversion_metrics_ts`; appointment outcomes = `fact_funnel_appointment_outcomes_daily` (CLIENT_APPOINTMENTS). Mart = `mart_funnel_conversion_metrics`; delivery = `v_funnel_conversion_power_bi`. Pre/post-tour follow up % remain NULL until CLIENT_TOUCHES discovery and logic.

---

## Notes

- The existing `funnel_property` cleaned model referred to `source('funnel', 'PROPERTY')`. In DS_FUNNEL_BH there is no view named PROPERTY; property/unit linkage is in **UNITS** and possibly **CLIENTS** / **GROUP_ASSIGNMENTS**. Align or rename `funnel_property` to match the share (e.g. point to UNITS or add a cleaned model for UNITS as `funnel_units`).
- DBT_CGENTRY and DBT_PROSPERO contain the same or a subset of view names; use STANDARD as the single source schema for cleaned models.
