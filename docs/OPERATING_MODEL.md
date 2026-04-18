# Operating model: Snowflake targets vs repos

## 1. `TRANSFORM.DEV` — SnowSQL only (not this dbt project’s default output)

**Who:** Hand-maintained SQL and operators.

**How:** Author and run scripts with **`snowsql -c pretium`** (or your CI Snowflake client). Scripts may live in **`pretium-ai-dbt`** under `scripts/sql/` (legacy pipeline DDL, COPY, stages, one-offs) or in this repo if you add a `scripts/sql/` tree here.

**Target:** Snowflake **`TRANSFORM`** database, **`DEV`** schema (`TRANSFORM.DEV` after default uppercasing) for landing tables, extracts, and dev mirrors — unless a script explicitly sets another database/schema.

**Do not** assume the **semantic-layer** dbt `dev` target writes here: this repo’s dbt `dev` target is wired to **semantic MART** databases (see `dbt_project.yml` `semantic_database_map`).

---

## 2. `ANALYTICS.DBT_DEV` — dbt in **this** repo (`pretiumdata-dbt-semantic-layer`)

**Who:** dbt Core in this repository.

**How:** `dbt run`, `dbt test`, CI — using a dbt **target** whose profile resolves to:

| Setting    | Value (convention) |
|-----------|---------------------|
| Database  | `ANALYTICS`         |
| Schema    | `DBT_DEV`           |

Use this for **analytics-layer** models (facts, dimensions, metrics prep) that you are moving or building alongside the semantic catalog.

**Profile:** Add or extend a target (e.g. `analytics_dev` or overload `dev`) in `profiles.yml` so `database=analytics` and `schema=dbt_dev` for local/CI runs. The starter `dbt_project.yml` in this repo still maps **`dev` → `MART_DEV.SEMANTIC`** for semantic marts; until analytics models are added under a separate config path, treat **“analytics.dbt_dev”** as the **intended Snowflake destination** for new analytics dbt work and align `profiles.yml` + `models:` blocks accordingly.

---

## 3. Summary

| Surface              | Repo                         | Tool    | Typical Snowflake location   |
|----------------------|------------------------------|---------|-------------------------------|
| Transform landings   | primarily **pretium-ai-dbt** | SnowSQL | **`TRANSFORM.DEV`**           |
| Analytics (dbt dev)  | **pretiumdata-dbt-semantic-layer** | dbt | **`ANALYTICS.DBT_DEV`** (via profile) |
| Semantic marts       | **pretiumdata-dbt-semantic-layer** | dbt | **`MART_DEV.SEMANTIC`** etc. (`semantic_database_map`) |

Keep cross-repo drift visible: if a table is created only in `TRANSFORM.DEV` via SnowSQL, document it in the repo that owns the script; if a relation is owned by dbt in this repo, it should appear in `models/` and `sources.yml` here.
