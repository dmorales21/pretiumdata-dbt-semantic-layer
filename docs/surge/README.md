# Surge documentation pack (pretiumdata-dbt-semantic-layer)

**Purpose:** Single entry point for a focused data-engineering surge. This folder **does not** replace canonical rules; it **orients** people to them.

**Print / PDF — single file:** merge of all chapters → **[`SURGE_BRIEF.md`](./SURGE_BRIEF.md)** (export this one to PDF).

**Canonical authority (read before changing layers or seeds):**

| Topic | Path |
|-------|------|
| Operating model (repos, ownership) | [`../OPERATING_MODEL.md`](../OPERATING_MODEL.md) |
| Architecture (layers, Jon vs Alex, metric gates) | [`../rules/ARCHITECTURE_RULES.md`](../rules/ARCHITECTURE_RULES.md) |
| Schema matrix (object placement, naming) | [`../rules/SCHEMA_RULES.md`](../rules/SCHEMA_RULES.md) |
| Migration procedure + legacy DB ban | [`../migration/MIGRATION_RULES.md`](../migration/MIGRATION_RULES.md) |
| Task register (`T-*`) | [`../migration/MIGRATION_TASKS.md`](../migration/MIGRATION_TASKS.md) |
| Docs index | [`../README.md`](../README.md) |

## Pack contents

| Document | Audience | Summary |
|----------|----------|---------|
| [`ENGINEER_ONBOARDING.md`](./ENGINEER_ONBOARDING.md) | Surge engineers | First-day setup, mental model, where to work, CI, “done” definition |
| [`ARCHITECTURE_OVERVIEW.md`](./ARCHITECTURE_OVERVIEW.md) | Surge engineers + leads | FACT → CONCEPT → FEATURE → MODEL → ESTIMATE; Snowflake homes |
| [`PROGRESS_SNAPSHOT_2026-04.md`](./PROGRESS_SNAPSHOT_2026-04.md) | Leadership + surge | Quantified snapshot: vendors, catalog, facts, concepts, analytics |
| [`VENDOR_AND_ANALYTIC_STUDIES_ROADMAP.md`](./VENDOR_AND_ANALYTIC_STUDIES_ROADMAP.md) | Surge + DS | Vendor onboarding queue + planned validation / governance studies |
| [`JON_PROD_HANDOFF_ROADMAP.md`](./JON_PROD_HANDOFF_ROADMAP.md) | **Jon** (PROD transform owner) | What Jon promotes, in what order, and how Alex’s `TRANSFORM.DEV` work attaches |
| [`REFERENCE_AND_AI.md`](./REFERENCE_AND_AI.md) | Everyone touching catalog or LLM apps | What `seeds/reference/` and `REFERENCE.*` are; how they connect to AI surfaces |

**Note on names:** Governing docs use **Jon** for Snowflake **`TRANSFORM.[VENDOR]`** PROD ownership. If your roster uses another spelling, align to the **Snowflake / org chart** owner for vendor canonical schemas.
