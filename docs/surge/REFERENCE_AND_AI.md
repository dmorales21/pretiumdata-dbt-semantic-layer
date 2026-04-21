# `reference/` — what it is, what it is for, and how it connects to AI

## 1. Two different meanings of “reference”

| Meaning | Where it lives | What it is |
|---------|----------------|------------|
| **A) Repo folder `seeds/reference/`** | Git-tracked CSV + YAML | **Authoring surface** for dimensions and catalog rows that become Snowflake **`REFERENCE.*`** tables when you `dbt seed` / build. |
| **B) Snowflake databases `REFERENCE.CATALOG`, `REFERENCE.GEOGRAPHY`, `REFERENCE.DRAFT`, (future) `REFERENCE.AI`** | Snowflake | **Runtime registry** consumed by dbt models, QA tests, apps, and (eventually) prompt stores. |

Engineers edit **A**; analysts and apps query **B**.

---

## 2. What `seeds/reference/` contains (high level)

### 2.1 `seeds/reference/catalog/` → **`REFERENCE.CATALOG`**

**Purpose:** Controlled vocabulary and **semantic registry** for the warehouse.

**Examples of seed files (not exhaustive):**

- **`concept.csv`** — analytic domains (`concept_code`) for **`CONCEPT_*`** unions and naming tokens.
- **`vendor.csv`**, **`dataset.csv`** — who produced data and which logical dataset / feed it is.
- **`metric.csv`** — **canonical metric registry** (grain, `table_path`, `geo_level_code`, `frequency_code`, `definition`, …). This file is the **long-term source of truth** for metric semantics in this repo.
- **`geo_level.csv`**, **`frequency.csv`**, **`function.csv`**, **`model_type.csv`**, **`estimate_type.csv`**, … — valid tokens for object names and YAML tests.
- **Bridges** — e.g. `bridge_product_type_metric.csv` links **product types** to **metrics** for serving and analytics contracts.
- **`metric_derived.csv` + `metric_derived_input.csv`** — registry for **analytics-layer** logical metrics (**FEATURE_** / **MODEL_** / **ESTIMATE_**) and their upstream metric dependencies.
- **`catalog_wishlist.csv`** — governed backlog / blocked items (still catalog-managed, but not “active contract”).

**Load order:** [`../CATALOG_SEED_ORDER.md`](../CATALOG_SEED_ORDER.md) — waves exist because of **foreign keys** between seeds.

### 2.2 `seeds/reference/draft/` → **`REFERENCE.DRAFT`**

**Purpose:** In-progress or experimental registry rows **not yet** promoted to **`REFERENCE.CATALOG`**. Safer place to iterate before tokens appear in production object names.

### 2.3 `models/reference/geography/` + geography seeds

**Purpose:** **`REFERENCE.GEOGRAPHY`** — **census spine**, H3 polyfills, ZIP–county–CBSA crosswalks that are **not vendor-specific**.

**Rule:** Never stash vendor-native crosswalks here — those belong in **`TRANSFORM.DEV` `REF_*`** (Alex) or **`TRANSFORM.[VENDOR]`** (Jon). See [`../rules/ARCHITECTURE_RULES.md`](../rules/ARCHITECTURE_RULES.md).

---

## 3. What reference data is **used for** in the stack

1. **Compile-time / CI governance:** dbt tests enforce relationships, allowed values, and seed ordering so broken tokens do not merge.
2. **Metric and object naming:** `SCHEMA_RULES` requires catalog tokens to exist **before** creating new **`FACT_*` / `CONCEPT_*` / `FEATURE_*`** objects that embed those tokens.
3. **Join keys and documentation:** `metric.definition`, `concept` descriptions, and dataset rows are the **authoritative** explanation of “what this column means” for humans **and** machines.
4. **QA surfaces:** Many `QA_*` models compare built tables to catalog expectations (coverage, lineage, parity).

---

## 4. How this translates to **AI** (practical)

**Today (shippable pattern):**

- **Retrieval-augmented analysis / agents** should treat **`REFERENCE.CATALOG.metric`** (especially **`definition`**, grain columns, and `table_path`) plus linked **`concept`** / **`dataset`** / **`vendor`** rows as **ground truth** when generating SQL, explaining series, or writing tear-sheet prose.
- **Feature / model code** in **`ANALYTICS.DBT_*`** should remain consistent with **`metric_derived`** registrations when those rows are active — see [`../reference/CATALOG_METRIC_DERIVED_LAYOUT.md`](../reference/CATALOG_METRIC_DERIVED_LAYOUT.md).

**Near-term target (`REFERENCE.AI`):**

- Architecture and operating model already reserve **`REFERENCE.AI`** for **prompt templates**, lens text, and offering-specific instructions.
- **`docs/reference/OFFERING_INTELLIGENCE_CANON.md`** describes how **Prism / tear-sheet** style configs should migrate from ad-hoc CSV exports into **governed** `REFERENCE.AI` rows (fragments, stack order, per-offering overrides).
- **Status:** seeds under `seeds/reference/ai/` are **not** fully present yet — the canon doc is the **design**; `metric.csv` is the **live** strict contract today.

**What not to do:**

- Do not train or prompt off **legacy** FQNs (`EDW_PROD`, old `ADMIN.CATALOG` paths) for new work — the canon doc explicitly warns about **deprecated path strings** in old prompt exports.

---

## 5. One-line summary for engineers

**`REFERENCE.CATALOG` is the dictionary + compiler symbol table for the warehouse; `REFERENCE.GEOGRAPHY` is the shared map; AI systems should read those dictionaries before hallucinating metric meanings — and `REFERENCE.AI` will eventually hold the governed natural-language lenses built on top.**
