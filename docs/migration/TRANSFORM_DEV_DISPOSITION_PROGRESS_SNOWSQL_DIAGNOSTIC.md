# **TRANSFORM.DEV** — Progress disposition facts vs OpCo footprint (SnowSQL diagnostic)

**Canonical dbt (source of truth):** [`models/transform/dev/progress_crm/`](../../models/transform/dev/progress_crm/) in this repo — **`fact_progress_disposition`** → **`fact_progress_disposition_latest`** materialize as **`TRANSFORM.DEV.FACT_PROGRESS_DISPOSITION`** and **`TRANSFORM.DEV.FACT_PROGRESS_DISPOSITION_LATEST`**.

**Gate:** `transform_dev_enable_disposition_yield_stack` (default **`false`** in `dbt_project.yml`). Models compile disabled until you pass **`--vars '{"transform_dev_enable_disposition_yield_stack": true}'`** and the role can read **`SOURCE_ENTITY.PROGRESS`** (`sfdc_disposition__c`, `sfdc_bpo__c`).

**Materialize (minimal):**

```bash
cd pretiumdata-dbt-semantic-layer
dbt run --select path:models/transform/dev/progress_crm \
  --vars '{"transform_dev_enable_disposition_yield_stack": true}'
```

Downstream yield stack (same var): **`concept_disposition_yield_property`**, **`ref_disposition_cherre_subject_bridge`**, disposition MODELs under **`models/analytics/model/disposition/`**.

---

## What **`snowsql -c pretium`** often shows

### `FACT_PROGRESS_DISPOSITION_LATEST`

- **Not usable** — `SELECT 1 FROM TRANSFORM.DEV.FACT_PROGRESS_DISPOSITION_LATEST` returns **`002003 (42S02): Object ... does not exist or not authorized`** (same symptom from dbt if the model never ran or grants block it).
- **`INFORMATION_SCHEMA.TABLES`** has **no** row for that name in **`TRANSFORM.DEV`**.

So for that connection the table is **missing** (or only exists under another database/schema your role cannot see — functionally the same for consumers).

### `FACT_OPCO_PROPERTY_PRESENCE`

- **Present** — **`INFORMATION_SCHEMA`** lists **`TRANSFORM` / `DEV` / `FACT_OPCO_PROPERTY_PRESENCE`** as **`BASE TABLE`**.
- **Selectable** — e.g. `SELECT COUNT(*)` can return on the order of **hundreds of thousands** of rows.

### What that implies

The failure is **not** “OpCo footprint missing”; it is specifically **`FACT_PROGRESS_DISPOSITION_LATEST`** not being in **`TRANSFORM.DEV`** (never built, stack var false, or not granted).

**Next steps:**

1. **Build here** — run **pretiumdata-dbt-semantic-layer** with the **`progress_crm`** path and **`transform_dev_enable_disposition_yield_stack: true`**, **or**
2. **Interim** — keep **`transform_dev_enable_disposition_yield_stack: false`** in any environment that must not depend on that table until it exists and is granted.

Asking for **`SELECT` on `TRANSFORM.DEV.FACT_PROGRESS_DISPOSITION_LATEST`** only succeeds once the object exists **and** your role is authorized.

**Legacy / dual-build note:** **pretium-ai-dbt** can still materialize the same Snowflake names from **`models/transform/dev/progress_crm/`** for migration; long-term ownership and EDW retirement follow **[OPERATING_MODEL.md](../OPERATING_MODEL.md)** and **[ARCHITECTURE_RULES.md](../rules/ARCHITECTURE_RULES.md)** — this repo’s **`models/`** tree is the contract surface.
