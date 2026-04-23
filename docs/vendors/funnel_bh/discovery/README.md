# Funnel BH column discovery for conversion metrics

**Purpose:** Capture column names and types for `CLIENT_APPOINTMENTS` and `CLIENT_TOUCHES` so we can implement Pre-Tour follow up %, Post-Tour follow up %, No show %, and Tour completed % without placeholders.

## Snowflake connection (discovery scripts)

Discovery scripts (`list_funnel_view_columns.py`, `list_funnel_views.py`, `list_funnel_listing_history_columns.py`, `list_funnel_object_columns.py`) connect using **one of** (first that works):

1. **Environment variables** — `SNOWFLAKE_ACCOUNT`, `SNOWFLAKE_USER` (required); optionally `SNOWFLAKE_WAREHOUSE`, `SNOWFLAKE_ROLE`, `SNOWFLAKE_AUTHENTICATOR`.
2. **dbt profile** — `~/.dbt/profiles.yml` with profile `pretium_data` or `pretium`, target `dev`/`prod`. Values like `{{ env_var('SNOWFLAKE_ACCOUNT') }}` are resolved from the environment.
3. **SnowSQL config** — `~/.snowsql/config` with `[connections.pretium]` (or `SNOWSQL_CONN=other_name`). Use `accountname`, `username`, `warehousename`, `rolename`, `authenticator`.

See **[HOW_WE_RUN_SNOWFLAKE_SQL.md](../../HOW_WE_RUN_SNOWFLAKE_SQL.md)** for SnowSQL and dbt. You do not need to set every env var if you already use a dbt profile or SnowSQL named connection.

## Run discovery

From repo root (with Snowflake connection configured as above and `.venv` activated):

```bash
./scripts/discovery/run_funnel_discovery_for_conversion_metrics.sh
```

Or per view:

```bash
.venv/bin/python scripts/discovery/list_funnel_view_columns.py CLIENT_APPOINTMENTS
.venv/bin/python scripts/discovery/list_funnel_view_columns.py CLIENT_TOUCHES
```

Save output to `docs/vendors/funnel_bh/discovery/CLIENT_APPOINTMENTS_columns.txt` and `CLIENT_TOUCHES_columns.txt` if you want it in repo.

**Variant (OBJECT) columns across all funnel views:**

```bash
snowsql -c pretium -f scripts/discovery/funnel_object_columns.sql
```

Or: `.venv/bin/python scripts/discovery/list_funnel_object_columns.py`

Save output to `docs/vendors/funnel_bh/discovery/OBJECT_COLUMNS_INVENTORY.txt` and see **[FUNNEL_VARIANT_COLUMNS_INVENTORY.md](../FUNNEL_VARIANT_COLUMNS_INVENTORY.md)** for extraction status (65 OBJECT columns across 24 views).

**After discovery:** If `fact_funnel_appointment_outcomes_daily` fails with `invalid identifier`, set in `dbt_project.yml` under `vars` the exact column names from the discovery output:
- `funnel_appointment_date_column`: the column for appointment date/time (e.g. `CREATED_AT`, `APPOINTMENT_START`, `START_TIME`).
- `funnel_appointment_status_column`: the column for appointment status. The model supports **variant/alternative types**: (1) integer column (e.g. `STATUS`, `STATUS_ID`); (2) OBJECT/VARIANT with `id` key (e.g. `APPOINTMENT_STATUS`); (3) VARCHAR JSON string (e.g. `'{"id": 50}'`). Funnel API: 50 = Completed, 60 = No Show.

## Funnel API reference (appointments)

From [Funnel Appointments API](https://developers.funnelleasing.com/api/v2/appointments.html):

| Status (integer) | Meaning        |
|------------------|----------------|
| null             | Created in app, not toggled |
| 10               | Tentative      |
| 20               | Not Confirmed  |
| 30               | Confirmed      |
| 40               | Cancelled      |
| **50**           | **Completed** (tour completed) |
| **60**           | **No Show**    |

The Snowflake view `DS_FUNNEL_BH.STANDARD.CLIENT_APPOINTMENTS` likely exposes a **STATUS** (or similar) column with these values, and a **START** (or APPOINTMENT_START / START_TIME) for the appointment datetime. Community/geo may be **COMMUNITY_ID**, **PMS_COMMUNITY_ID**, **GROUP_ID**, or require a join to another view. After running discovery, update `fact_funnel_appointment_outcomes_daily.sql` and `fact_funnel_conversion_metrics_ts.sql` if column names differ.

## CLIENT_TOUCHES (follow-up %)

Pre-Tour follow up % and Post-Tour follow up % require knowing:

- When each touch occurred (e.g. **TOUCH_DATE** or **CREATED_AT**).
- Which client/prospect (e.g. **CLIENT_ID**).
- Optionally, type of touch (call, email, etc.).

Then join to appointments to classify touches as before or after the first appointment (pre-tour vs post-tour). After discovery, add logic to the conversion metrics or a dedicated touches model.
