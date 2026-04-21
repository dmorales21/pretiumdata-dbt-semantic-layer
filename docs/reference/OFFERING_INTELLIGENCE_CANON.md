# Offering intelligence — canonical contract (`REFERENCE.CATALOG` + `REFERENCE.AI`)

**Canon:** This document, plus the **seeded** tables under **`REFERENCE.CATALOG`** and (when implemented) **`REFERENCE.AI`** in **`pretiumdata-dbt-semantic-layer`**, define the **Snowflake source of truth** for offering-aware catalog rows and **tear-sheet / Prism** prompt bodies consumed by governed apps.

**Non-canon (upstream specs):** The **analytics-engine** ontology YAMLs and markdown guides are the **logical** specification for concepts, arbitrage profiles, weights, and market metric vocabulary. This repo **does not** duplicate those files; it **links** them and describes how they **map into** catalog seeds and AI prompt registration.

**Context artifact — `postal_xwalks_2026-04-20-0049.csv`:** Despite the filename, the export is **not** a USPS or ZCTA crosswalk. It is a **Prism prompt-configuration extract** with columns `CONFIG_ID`, `TEMPLATE_ID`, `SECTION_ID`, `PROMPT_KEY`, `PROMPT_TEXT`, `CREATED_AT`. The **40 logical rows** are:

| Role | `CONFIG_ID` pattern | `SECTION_ID` | `PROMPT_KEY` |
|------|---------------------|--------------|--------------|
| Global system preamble | `cfg_global_intro` | `global` | `system_intro` |
| Shared market tear-sheet lens | `cfg_market_tearsheet_lens` | `market_tearsheet` | `lens_instruction` |
| Other product lenses | `cfg_underwriting_lens`, `cfg_studio_lens`, `cfg_general_lens` | `underwriting` / `studio` / `general` | `lens_instruction` |
| **Per-offering** tear-sheet override | `cfg_tearsheet_<slug>` (e.g. `cfg_tearsheet_req_btr_comm`, `cfg_tearsheet_red_hbf`) | `market_tearsheet` | `lens_instruction` |
| Vertical roll-ups | `cfg_tearsheet_req`, `cfg_tearsheet_red`, `cfg_tearsheet_resi`, `cfg_tearsheet_agnostic` | `market_tearsheet` | `lens_instruction` |

Treat that CSV as **evidence of the current Prism prompt inventory** when designing **`REFERENCE.AI`** rows—not as geography data.

---

## 1) Split of responsibility

| Concern | Canonical location | Notes |
|--------|-------------------|--------|
| **Concept ids**, causal graph, measurement semantics | Analytics-engine `registry/ontology/CANONICAL_CONCEPT_ONTOLOGY.yml` | Join keys in YAML are **ontology concept ids** (e.g. `absorption_tightness`, `value_avm`). |
| **Per-offering thesis**, `required_signals`, risks | Analytics-engine `registry/ontology/OFFERING_ARBITRAGE_PROFILE.yml` | Must validate against ontology; only a subset of capital offerings may have rows initially. |
| **Offering × concept weights** | Analytics-engine `registry/ontology/OFFERING_CONCEPT_WEIGHT_MATRIX.yml` | Relative emphasis; floor for required signals in that file. |
| **Capital offering catalog**, narrative, metric dictionary | Analytics-engine `docs/guide_offerings.md`, `docs/guide_offerings_market.md` | Part 2A = stable **`offering_id`** list; market guide = **`metric_id`** / tiers / geo levels. |
| **Registry path contract** | Analytics-engine `registry/ontology/REGISTRY_PATH_INDEX.yml` | CI “files must exist” for analytics-engine repo. |
| **Snowflake dimensions** (`concept`, `offering`, bridges, `metric`, …) | **`seeds/reference/catalog/*.csv`** → **`REFERENCE.CATALOG`** | **Enforcement:** [`SCHEMA_RULES.md`](../rules/SCHEMA_RULES.md) §1 — tokens used in governed object names need active catalog rows. |
| **Prompt templates / lens text** (Prism, tear sheet, IC) | **`REFERENCE.AI`** (target) | Declared in [`SCHEMA_RULES.md`](../rules/SCHEMA_RULES.md) and [`OPERATING_MODEL.md`](../OPERATING_MODEL.md); **seeds not yet present** in this repo as of this document—implement under `seeds/reference/ai/` with schema YAML following the same pattern as `seeds/reference/catalog/`. |

---

## 2) `prompt_tearsheet_offering` — naming and keys

**Meaning:** The **logical prompt family** for the **market tear sheet** surface when an **`offering_code`** (or capital **`offering_id`**) is active. It is the dbt/catalog-friendly name for what Prism stores as **`cfg_tearsheet_*` + `lens_instruction`** (and layers on top of **`cfg_market_tearsheet_lens`** in the app).

**Canonical key strategy (recommended):**

1. **`prompt_use_case_code`:** `tearsheet_offering` (stable enum in catalog when you add an AI prompt dimension table, or free-text in a first-pass seed).
2. **`offering_code`:** FK to **`REFERENCE.CATALOG.offering.offering_code`**, aligned to capital SKUs from `guide_offerings.md` Part 2A (e.g. `RED_HBF`, `REQ_BTR_COMM`). Prism export uses snake case in `CONFIG_ID` (`cfg_tearsheet_red_hbf`); **normalize to uppercase `offering_id` / `offering_code`** at ingest to match the guide and seeds.
3. **`prompt_key`:** `lens_instruction` | `system_intro` | … — mirrors the export’s `PROMPT_KEY` for traceability.
4. **`prompt_version` / `effective_date`:** Required for change control (Prism export has `CREATED_AT` only; Snowflake should carry version semantics).

**Composition rule (product):** Resolved prompt = **`system_intro`** + **base `cfg_market_tearsheet_lens`** + **per-offering override** when `cfg_tearsheet_<offering>` exists; else vertical aggregate (`cfg_tearsheet_req` / `red` / `resi`) or `cfg_tearsheet_agnostic`. Document this stacking in the app; **`REFERENCE.AI`** can store **fragments** as separate rows with a **`prompt_stack_order`** or equivalent when you add columns.

---

## 3) `REFERENCE.CATALOG` — knowledge still to build

Ontology and guides assume a **richer** graph than today’s `concept.csv` / `offering.csv`:

| Gap | Action |
|-----|--------|
| **Concept id mismatch** | Ontology uses ids such as `absorption_tightness`, `household_demographics_demand`, `value_avm`. Catalog today uses `absorption`, `home_price`, `population`, `income`, etc. Add a **bridge** (new seed `concept_ontology_alias` or extend `concept` with optional `ontology_concept_id`) so **`OFFERING_ARBITRAGE_PROFILE.required_signals`** and **`offering_signal_relevance`** can both resolve. |
| **Offering grid** | `offering.csv` currently holds analytics products (`property_tearsheet_resi`, …), not the full **RED / REQ / RESI** capital grid from `guide_offerings.md` Part 2A. Add rows (or a dedicated `capital_offering` dimension) for each **`offering_id`** that has a **`cfg_tearsheet_*`** row and FK prompts to them. |
| **Arbitrage + weights** | No seed yet for **`OFFERING_ARBITRAGE_PROFILE`** / **`OFFERING_CONCEPT_WEIGHT_MATRIX`**. Add tables under **`REFERENCE.CATALOG`** (or **`REFERENCE.DRAFT`** first) with dbt tests: FK to `offering`, FK to `concept` (via bridge), numeric checks on weights. |
| **Market metrics** | `guide_offerings_market.md` **`metric_id`** list must map to **`metric`** / **`metric_derived`** and implemented **`TRANSFORM.DEV`** / **`CONCEPT_*`** / **`FEATURE_*`** objects. Use [`METRIC_INTAKE_CHECKLIST.md`](../migration/METRIC_INTAKE_CHECKLIST.md) and [`SERVING_DEMO_METRICS_CATALOG_MAP.md`](./SERVING_DEMO_METRICS_CATALOG_MAP.md). |
| **`offering_signal_relevance`** | Today’s CSV ties **product** offerings to catalog concepts. Extend or parallel with **capital-offering** rows keyed by `RED_HBF` / `REQ_BTR_COMM`, tiers aligned to market guide (`required` / `recommended` / …). |

---

## 4) `REFERENCE.AI` — knowledge still to build

| Step | Action |
|------|--------|
| **Create seed package** | e.g. `seeds/reference/ai/` + `schema_ai_prompt.yml`, database **`REFERENCE`**, schema **`AI`** (per [`SCHEMA_RULES.md`](../rules/SCHEMA_RULES.md) matrix rows for AI Prompt Templates). |
| **Ingest Prism export** | One-time or repeatable pipeline: map `CONFIG_ID` → stable **`prompt_id`**, `PROMPT_TEXT` → body, preserve `TEMPLATE_ID` / `SECTION_ID` as metadata columns. |
| **Deprecate legacy paths in text** | Export text references **`EDW_PROD`**, **`ADMIN.CATALOG`**, **MART** in places. For new canon, prompts that go to **`REFERENCE.AI`** should be **edited** to reference **current** governed FQNs (`TRANSFORM.DEV`, `MART_*`.`SEMANTIC`, `REFERENCE.CATALOG`) per migration policy—**do not** copy verbatim without review ([`MIGRATION_RULES.md`](../migration/MIGRATION_RULES.md) legacy DB ban in dbt graph applies to new SQL in models; **prompt prose** should still avoid steering analysts to retired stores). |
| **Tests** | Every `offering_code` in prompt seeds → `relationships` to `offering`. Optional: script that diffs analytics-engine **`REGISTRY_PATH_INDEX.yml`** paths vs last ingest. |

---

## 5) Cross-repo pointers (read-only specs)

Paths are on the **analytics-engine** clone (adjust if your layout differs):

- `registry/ontology/CANONICAL_CONCEPT_ONTOLOGY.yml`
- `registry/ontology/OFFERING_ARBITRAGE_PROFILE.yml`
- `registry/ontology/OFFERING_CONCEPT_WEIGHT_MATRIX.yml`
- `registry/ontology/REGISTRY_PATH_INDEX.yml`
- `docs/guide_offerings.md`
- `docs/guide_offerings_market.md`

---

## 6) Related docs in this repo

| Topic | Path |
|-------|------|
| Tearsheet / ADMIN / DIM lineage (migration) | [`../migration/MIGRATION_TASKS_TEARSHEET_SERVICE.md`](../migration/MIGRATION_TASKS_TEARSHEET_SERVICE.md) |
| Offering / tenant / tearsheet catalog seeds | `seeds/reference/catalog/schema_offering_tearsheet.yml`, `offering.csv`, `offering_signal_relevance.csv` |
| Catalog seed waves | [`../CATALOG_SEED_ORDER.md`](../CATALOG_SEED_ORDER.md) |
| Metric-derived registry | [`./CATALOG_METRIC_DERIVED_LAYOUT.md`](./CATALOG_METRIC_DERIVED_LAYOUT.md) |

---

## 7) Summary

- **Canon for Snowflake** = **this repo’s** `REFERENCE.CATALOG` seeds + future **`REFERENCE.AI`** seeds/models.  
- **Canon for ontology / offering math / market dictionary** = **analytics-engine** files above; **sync** via explicit mapping seeds and CI, not copy-paste drift.  
- **`postal_xwalks_*.csv`** = **Prism prompt export** (40 configs); use it to bootstrap **`prompt_tearsheet_offering`** (per-offering lens rows) and related **`REFERENCE.AI`** content after schema + governance review.
