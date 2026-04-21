# Systematize market-relevant data as **`TRANSFORM.DEV` `FACT_*`**

**Audience:** Alex + data consumers  
**Governs:** `MIGRATION_RULES.md` §2 (layer rules), `DEPRECATION_MIGRATION_COMPLIANCE.md` (five-target contract).

**Goal:** Bring **non-deal**, **market / reference** series into **one pattern**: typed **`FACT_*`** (and later **`CONCEPT_*`**) in **`TRANSFORM.DEV`**, registered in **`REFERENCE.CATALOG`**, joinable to **`REFERENCE.GEOGRAPHY`**, testable in dbt.

**Analytics stack (features, scoring, estimation, data prep, labor risk):** use the consolidated **[MODEL_FEATURE_ESTIMATION_PLAYBOOK.md](./MODEL_FEATURE_ESTIMATION_PLAYBOOK.md)** — this file stays **`FACT_*`-first**; that file owns **`FEATURE_*` / `MODEL_*` / `ESTIMATE_*`** semantics and corridor / ML prep.

---

## 1. What counts as a “fact” here

| Include | Exclude |
|---------|---------|
| **Geo × time × segment** (or **geo × variable** EAV) usable across deals | Deal thesis, IC narrative, asset-manager overrides |
| **Vendor or government** measures with a stable grain | One-off extracts with no grain contract |
| Objects you want in **Strata / apps / Looker** as `TRANSFORM.DEV.FACT_*` | Raw landings (**`SOURCE_PROD.*.RAW_*`**) as the long-term home for logic |

**Naming:** `fact_<vendor_or_domain>_<topic>_<geo>_<freq>.sql` under **`models/transform/dev/<folder>/`**, **`alias=`** matching Snowflake **`FACT_*`**.

---

## 2. Ingestion waves (do in order)

| Wave | Scope | Primary sources | Catalog / docs |
|------|--------|-----------------|----------------|
| **A — Geography spine** | Join keys, LEVEL crosswalks | **`REFERENCE.GEOGRAPHY`** (Cybersyn `geography_*` → dictionary); drive **`unmapped`** to zero | `CYBERSYN_GLOBAL_GOVERNMENT_BRING_IN_MATRIX.md`, `geo_level.csv` |
| **B — Jon silver read-throughs** | Thin **`FACT_*`** views over **`TRANSFORM.<VENDOR>`** | BPS, BLS LAUS, LODES, Census ACS5 (when agreed) | `MIGRATION_TASKS_TRANSFORM_BPS_CENSUS_BLS_LODES.md`, **`metric.csv`** MET_* rows |
| **C — Cybersyn housing MVP** | First **`FACT_*`** from share after A stable | Matrix **shortlist** (real estate, HUD, ACS, IRS migration, USPS AC) | `MIGRATION_TASKS_CYBERSYN_SOURCE_SNOW.md`, matrix § shortlist |
| **D — Cherre market stack** | Assessor, MLS, recorder, AVM, demographics at **market** grain | **`TRANSFORM.CHERRE`** + `source('cherre',…)` | `MIGRATION_TASKS_CHERRE.md`, **DS_025–DS_030**, pretium-ai-dbt **`dim_dataset_config`** CHERRE rows |
| **E — Concept methods** | **`CONCEPT_*`** from approved **`FACT_*`** combos | Registry `concept_methods` | `MIGRATION_TASKS_CONCEPT_METHOD_FACT_PRIORITIES.md` |
| **F — Analytics (rent + generic)** | **`FEATURE_*` / `MODEL_*` / `ESTIMATE_*`** on **`ANALYTICS.DBT_DEV`** only after E | `ref('fact_*')`, `ref('concept_*')` | `MIGRATION_RULES.md` §2; **rent DAG:** `MIGRATION_TASKS_EF_RENT_PREBAKED_METRICS.md`; **prep + estimation contract:** `MODEL_FEATURE_ESTIMATION_PLAYBOOK.md` |
| **G — Labor & automation exposure** | O*NET / QCEW / Epoch → county **`FACT_*`**, then **`FEATURE_*`** structural risk, **`MODEL_*`** indices | Same as F; upstream cleanses per pretium-ai-dbt `AI_REPLACEMENT_AND_AIGE_DATA_DEPENDENCIES.md` | **`T-ANALYTICS-LABOR-AUTOMATION-RISK-STACK`** in `MIGRATION_TASKS.md` |

Skip or de-prioritize matrix **tier 99** / non-housing Cybersyn domains until a product asks for them.

---

## 3. Checklist per new **`FACT_*`**

1. **Physical read path** — `source()` to **`TRANSFORM.[VENDOR]`**, **`SOURCE_PROD`**, or **`SOURCE_SNOW`** per `MIGRATION_BASELINE_RAW_TRANSFORM.md` §1 priority (no hardcoded FQNs).
2. **Grain contract** — Document PK / dedupe keys in **`schema.yml`** (date × geo × measure, etc.).
3. **`GEO_LEVEL_CODE` / FIPS / GEO_ID`** — Must map through **`REFERENCE.GEOGRAPHY`** / **`REFERENCE.CATALOG.geo_level`**; no raw Cybersyn **`LEVEL`** strings on facts (`MIGRATION_RULES.md` §6–7).
4. **`REFERENCE.CATALOG`** — Add or update **`dataset.csv`** row; add **`metric.csv`** rows with **`table_path` = `TRANSFORM.DEV.FACT_…`** and correct **`vendor_code`** (not “Cybersyn” when the agency is IRS/HUD/etc.).
5. **Tests** — `not_null` on keys; optional **relationships** to **`ref('geo_level')`** or small smoke row counts; document heavy scans in migration SQL scripts, not CI, where needed.
6. **Log** — Append **`MIGRATION_LOG.md`** when a batch lands; tick **`MIGRATION_TASKS.md`** **`T-*`** row.

---

## 4. Cybersyn-specific note

- **Geography registry** tables stay **`REFERENCE.GEOGRAPHY`** (not **`FACT_*`**).
- **Timeseries / attributes** from Cybersyn (`*_timeseries`, `*_attributes`) become **`FACT_*`** only after **Wave A** and **dictionary** alignment; join **`GEO_ID`** via **`REFERENCE.GEOGRAPHY.GEOGRAPHY_INDEX`** and map variables to **`metric_id`** (or narrow `metric_code` set) in **`metric.csv`**.

---

## 5. “All relevant data” scope control

Use three filters so the backlog stays shippable:

1. **Product hope-list** — `MIGRATION_TASKS_CHERRE.md` §2 tabs (Scope / Assess / Price / …) + government spine (BPS/BLS/LODES/ACS) + Cybersyn MVP shortlist.
2. **`dim_dataset_config.csv`** (pretium-ai-dbt) — already lists **147** dataset bundles; migrate **active** rows tied to live **`FACT_*`** first.
3. **Cybersyn matrix tiers 1–6** — ignore tier **99** until explicitly in scope.

---

## 6. Commands (local loop)

```bash
cd pretiumdata-dbt-semantic-layer/pretiumdata-dbt-semantic-layer
dbt seed --select geo_level vendor dataset metric cybersyn_catalog_table_vendor_map
dbt run --select path:models/transform/dev path:models/reference/geography
dbt test --select path:models/transform/dev path:models/reference/geography cybersyn_catalog_table_vendor_map
```

Expand `--select` as you add folders (`cherre/`, future `cybersyn/`, etc.).
