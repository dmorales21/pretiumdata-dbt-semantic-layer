# Funnel Conversion Metrics – Data Access & Power BI Connection Guide

**Audience:** Report owners, business users, Power BI developers  
**Last updated:** February 2026  
**Companion:** [FUNNEL_DATA_TRANSFORMATION_BUSINESS.md](FUNNEL_DATA_TRANSFORMATION_BUSINESS.md) (metrics definitions), [sample_funnel_conversion_power_bi.csv](sample_funnel_conversion_power_bi.csv) (sample data)

---

## 1. Data Access Instructions

### 1.1 What You Get Access To

| Object | Location | Purpose |
|--------|----------|---------|
| **Funnel conversion (Power BI)** | `EDW_PROD.DELIVERY.V_FUNNEL_CONVERSION_POWER_BI` | One table for all funnel conversion metrics (wide: one row per date + community, one column per metric). Use this for Power BI and most reporting. |
| **Funnel conversion (long)** | `EDW_PROD.MART.mart_funnel_conversion_metrics` | Same metrics in long format (one row per date, community, metric). Use for time-series or multi-metric analysis. |

No other tables are required for funnel conversion reporting.

### 1.2 Prerequisites

- **Snowflake account:** You must have a Snowflake login (user/password or SSO) for the same Snowflake account where EDW_PROD is deployed.
- **Role:** Your Snowflake role must have **SELECT** on:
  - `EDW_PROD.DELIVERY.V_FUNNEL_CONVERSION_POWER_BI` (for Power BI and reporting), and optionally
  - `EDW_PROD.MART.mart_funnel_conversion_metrics` (for long-format analysis).
- **Warehouse:** A warehouse must be assigned to your role (for query execution). Your admin may use a shared reporting warehouse (e.g. `REPORTING_WH`) or a personal one.

### 1.3 How to Request Access

1. **Contact:** Request access through your normal channel (e.g. Data Engineering, IT, or the data product owner for Funnel).
2. **Specify:** Ask for **read (SELECT)** access to:
   - Database: `EDW_PROD`
   - Schema: `DELIVERY`
   - View: `V_FUNNEL_CONVERSION_POWER_BI`
3. **Optional (analysts):** If you need long-format data, also request SELECT on `EDW_PROD.MART.mart_funnel_conversion_metrics`.
4. **Power BI / service accounts:** If a Power BI dataset uses a dedicated Snowflake user (e.g. service account), that user must have the same SELECT privileges and a warehouse assigned.

### 1.4 Accessing Data in Snowflake (SQL / Snowsight)

- **Snowsight (Snowflake UI):** Log in → **Worksheets** → run SQL against the view.
- **Example query:**
  ```sql
  SELECT *
  FROM EDW_PROD.DELIVERY.V_FUNNEL_CONVERSION_POWER_BI
  WHERE date_reference >= DATEADD(day, -30, CURRENT_DATE())
  ORDER BY date_reference DESC, geo_id
  LIMIT 1000;
  ```
- **Sample data:** For a small sample of the delivered metrics (column layout and example values), see [sample_funnel_conversion_power_bi.csv](sample_funnel_conversion_power_bi.csv) in this folder.

### 1.5 Refresh Cadence

- Data in the view is produced by the dbt pipeline (Funnel demand + conversion models). Pipeline runs are owned by Data Engineering (schedule may be daily or as agreed).
- **Power BI:** Schedule your dataset refresh **after** the pipeline has run so that the view reflects the latest data. Align the refresh time with your Data Engineering team.

---

## 2. Power BI Connection Guide

Follow these steps to connect Power BI Desktop (or the Power BI service) to the Funnel conversion metrics.

### 2.1 Get Data – Snowflake

1. Open **Power BI Desktop** (or create a new report in the Power BI service).
2. **Get Data** → **Database** → **Snowflake** → **Connect**.
3. If Snowflake is not listed, install the latest Power BI Desktop updates or add the Snowflake connector from the marketplace if you use a custom connector.

### 2.2 Server (Snowflake Account)

1. In the **Server** field, enter your Snowflake account identifier. Use one of these forms:
   - **Account locator (recommended):** `your_account_locator` (e.g. `xy12345.us-east-1`, or `xy12345.us-east-2.aws`).
   - **Full URL:** `https://your_account_locator.snowflakecomputing.com`
2. **Do not** include `https://` in the Server field if your connector expects only the account locator.
3. If you use SSO, ensure the connector supports it and that your Snowflake account has SSO configured.

### 2.3 Database and Schema

1. **Database (optional in some connectors):** Enter `EDW_PROD`. If the connector has a single “Database” box, use `EDW_PROD`.
2. **Schema (optional):** Enter `DELIVERY`. Some connectors infer schema from the table; if you must pick a schema, choose `DELIVERY`.
3. **Table / View:** Select or type **`V_FUNNEL_CONVERSION_POWER_BI`** (the view name).

**Summary:**

| Field | Value |
|-------|--------|
| Server | Your Snowflake account locator (e.g. `xy12345.us-east-1`) |
| Database | `EDW_PROD` |
| Schema | `DELIVERY` |
| Table / View | `V_FUNNEL_CONVERSION_POWER_BI` |

### 2.4 Authentication

1. Choose the authentication method configured for your organization:
   - **Snowflake (user + password):** Enter your Snowflake username and password. For Power BI service scheduled refresh, use a service account or stored credentials.
   - **OAuth / SSO:** If your Snowflake and Power BI are set up for SSO, select the appropriate option and sign in when prompted.
2. **Power BI service (scheduled refresh):** Configure a gateway or use a cloud connection; store credentials (e.g. Snowflake user/password or OAuth) in the dataset’s data source settings so refresh runs without manual login.

### 2.5 Load and Model

1. Click **OK** (or **Load**). Power BI will connect and show the columns of `V_FUNNEL_CONVERSION_POWER_BI`.
2. **Load:** Choose **Load** to import the data, or **Transform data** to open Power Query and apply filters (e.g. last 90 days) before loading.
3. **Recommended:** For large history, consider filtering in Power Query by `date_reference` (e.g. last 12 months) to keep the dataset size manageable.
4. **Full table list for refresh:** For this report, the only object you need to refresh is **EDW_PROD.DELIVERY.V_FUNNEL_CONVERSION_POWER_BI**. No other tables are required for funnel conversion metrics.

### 2.6 Scheduled Refresh (Power BI Service)

1. Publish the report to the **Power BI service**.
2. Open **Settings** → **Datasets** → your dataset → **Scheduled refresh**.
3. Set the refresh schedule (e.g. daily) to run **after** the dbt pipeline that builds the view (coordinate with Data Engineering).
4. Ensure the data source credentials (Snowflake user/password or SSO) are set and that the Snowflake user has SELECT on `EDW_PROD.DELIVERY.V_FUNNEL_CONVERSION_POWER_BI` and a warehouse assigned.

### 2.7 Troubleshooting

| Issue | What to check |
|-------|----------------|
| "Cannot connect" or "Login failed" | Verify Server (account locator), username, password, and that your Snowflake role has access to EDW_PROD. |
| "Object does not exist" | Confirm Database = `EDW_PROD`, Schema = `DELIVERY`, Table/View = `V_FUNNEL_CONVERSION_POWER_BI` (case may matter depending on Snowflake quoting). |
| No data or old data after refresh | Ensure the dbt pipeline has run, then run a manual refresh. Check with Data Engineering that the pipeline is successful. |
| Slow refresh | Consider filtering by `date_reference` in Power Query to reduce rows (e.g. last 365 days). |

---

## 3. Sample Data (CSV)

A small sample of the delivered metrics (same columns as `V_FUNNEL_CONVERSION_POWER_BI`) is provided for reference and testing:

- **File:** [sample_funnel_conversion_power_bi.csv](sample_funnel_conversion_power_bi.csv)
- **Location:** Same folder as this guide: `docs/vendors/funnel_bh/`
- **Contents:** Example rows with one row per (date_reference, geo_id) and one column per metric. Values are illustrative; Pre-Tour and Post-Tour follow up % are left empty (NULL) as in production until CLIENT_TOUCHES is wired.
- **Use:** Check column names and value ranges when building reports or validating the Power BI connection.

---

## 4. Quick Reference

| Need | Value |
|------|--------|
| **Database** | `EDW_PROD` |
| **Schema** | `DELIVERY` |
| **View (Power BI)** | `V_FUNNEL_CONVERSION_POWER_BI` |
| **Mart (long format)** | `EDW_PROD.MART.mart_funnel_conversion_metrics` |
| **Sample data** | [sample_funnel_conversion_power_bi.csv](sample_funnel_conversion_power_bi.csv) |
| **Metric definitions** | [FUNNEL_DATA_TRANSFORMATION_BUSINESS.md](FUNNEL_DATA_TRANSFORMATION_BUSINESS.md) |
