# Migration readiness — Stanford SEDA (`SOURCE_PROD.STANFORD`, `TRANSFORM.STANFORD`, `TRANSFORM.DEV`) and Redfin (`TRANSFORM.REDFIN`, `RAW.REDFIN`, `SOURCE_PROD.REDFIN`)

**Owner:** Alex  
**Governing docs:** `MIGRATION_RULES.md`, `MIGRATION_BASELINE_RAW_TRANSFORM.md` §1–2, pretium-ai-dbt `design/final/DEPRECATION_MIGRATION_COMPLIANCE.md`

**Task IDs (update `MIGRATION_TASKS.md`):**

| Task ID | Scope | Status |
|---------|--------|--------|
| **T-VENDOR-REDFIN-READY** | **`TRANSFORM.REDFIN`** tracker views + optional **`RAW.REDFIN`** / **`SOURCE_PROD.REDFIN`** + cleaned / facts | `pending` |
| **T-VENDOR-STANFORD-READY** | **`SOURCE_PROD.STANFORD`** VARIANT parquet + **`TRANSFORM.STANFORD`** typed surface (if deployed) + **`TRANSFORM.DEV`** `FACT_STANFORD_*` | `pending` |

**Canonical workbook:** `pretiumdata-dbt-semantic-layer/scripts/sql/migration/inventory_stanford_redfin_for_dev_facts.sql`  
**Snowflake CLI paths:** if `snowsql -f …` returns **No such file**, see `docs/migration/artifacts/README.md` (nested `pretiumdata-dbt-semantic-layer/` folder vs inner `scripts/…` only).

| Script blocks | Part | Purpose |
|---------------|------|---------|
| **RF-A – RF-I** | A | Redfin objects, columns, counts, ZIP dup grain, splits, RAW + SOURCE_PROD listing |
| **ST-A – ST-G** | B | Stanford TRANSFORM / SOURCE_PROD / RAW lists, columns, **OBJECT_KEYS**, counts, **FILE_NAME** mix, crosswalk dup |

---

## Part A — Redfin

### A0. Physical homes (read priority)

| Location | Role |
|----------|------|
| **`TRANSFORM.REDFIN`** | **Interim** market-tracker **latest** views (ZIP / county / metro) — primary dbt `source('redfin', …)` today (`database: transform`). |
| **`SOURCE_PROD.REDFIN`** | **Canonical target** for full-history ZIP/MSA tables (`source_redfin` in `sources.yml`) — align `MIGRATION_BASELINE` §1 when DE promotes views. |
| **`RAW.REDFIN`** | Legacy mirror (baseline **~7** objects) — prefer **`TRANSFORM.REDFIN`** unless row missing. |

pretium-ai-dbt `sources.yml` **`redfin`** block documents **`interim_source: true`** and **`canonical_target: source_prod`** — migration must not silently assume **`TRANSFORM`** is permanent.

### A1. Object inventory

- [ ] Run **`scripts/sql/migration/inventory_stanford_redfin_for_dev_facts.sql`** blocks **RF-A / RF-B**.
- [ ] If **`SOURCE_PROD.REDFIN`** is live for your account, run **RF-I** (parity / existence).
- [ ] Reconcile **`INFORMATION_SCHEMA`** list to declared tables: `REDFIN_ZIPCODE_MARKET_TRACKER_LATEST`, `REDFIN_COUNTY_MARKET_TRACKER_LATEST`, `REDFIN_METRO_MARKET_TRACKER_LATEST`, and commented “future” objects (city / neighborhood / state / national) in `sources.yml`.

### A1.5 Uniques and grain (required before new `FACT_*`)

**Operational note:** Run **RF-A → RF-B** first and export. If **RF-D** fails (unknown columns), align identifiers from **RF-B** vs `DESCRIBE TABLE` and `cleaned_redfin_market_tracker_zipcode.sql`.

- [ ] **RF-C–RF-E:** row counts, ZIP duplicate-grain template (**RF-D**), **`PROPERTY_TYPE`** / **`STATE_CODE`** cardinality (**RF-E**).
- [ ] Optional **RF-F** / **RF-I** when reconciling **`RAW.REDFIN`** / **`SOURCE_PROD.REDFIN`**.
- [ ] Archive CSV outputs under `docs/migration/artifacts/`; link **`MIGRATION_LOG.md`**.

### A2. **Documented vs consumed columns (ZIP tracker)**

`cleaned_redfin_market_tracker_zipcode.sql` casts a **wide** set of Redfin columns (all **TEXT** upstream). Any column referenced there **must** exist on the physical latest view or the cleaned view fails at runtime.

**Representative required columns (non-exhaustive — diff against current cleaned SQL):**  
`PERIOD_BEGIN`, `TABLE_ID`, `REGION`, `PROPERTY_TYPE`, `MEDIAN_SALE_PRICE`, `MEDIAN_LIST_PRICE`, `MEDIAN_PPSF`, `MEDIAN_LIST_PPSF`, `MEDIAN_DOM`, `HOMES_SOLD`, `NEW_LISTINGS`, `INVENTORY`, `MONTHS_OF_SUPPLY`, `PENDING_SALES`, `AVG_SALE_TO_LIST`, `SOLD_ABOVE_LIST`, `PRICE_DROPS`, `OFF_MARKET_IN_TWO_WEEKS`, `*_MOM`, `*_YOY`, `STATE_CODE`, `CITY`, …

- [ ] `DESCRIBE TABLE TRANSFORM.REDFIN.<VIEW>;` for each tracker in use; compare to **`cleaned_redfin_market_tracker_*`** and **`fact_redfin_*`** selects.
- [ ] **`REFERENCE.CATALOG` `dataset.csv`:** **`DS_017`–`DS_019`** — refresh counts / `source_schema` after inventory (`TRANSFORM.REDFIN` vs `SOURCE_PROD.REDFIN` when flipped).

### A3. Semantic-layer

- [ ] **`sources_transform.yml`** declares **`redfin_avm_zip_monthly`**, **`redfin_housing_market_zip_monthly`** under **`TRANSFORM.FACT`** — reconcile naming with **`TRANSFORM.REDFIN`** latest views; document single read path per metric.

### A4. Exit (Redfin)

- [ ] Smoke **`SELECT 1`** on each active Redfin relation in the migration role.
- [ ] **`T-VENDOR-REDFIN-READY`** → `migrated` when A1–A3 + artifacts complete.

---

## Part B — Stanford / SEDA

### B0. Physical homes

| Location | Role |
|----------|------|
| **`SOURCE_PROD.STANFORD`** | **VARIANT** parquet tables (`STANFORD_SEDA_*_PARQUET`) + **`STANFORD_SEDA_FIELD_DICTIONARY`** — canonical landing per `sources.yml`. |
| **`TRANSFORM.STANFORD`** | Typed / narrowed **vendor** surface (baseline **~1** object in account inventory); `sources.yml` **`stanford_transform`** documents intended **`SEDA`** view — **meta note: “View not yet created.”** |
| **`TRANSFORM.DEV`** | **`FACT_STANFORD_SCHOOLS_COUNTY`**, **`FACT_STANFORD_SEDA_COUNTY_SNAPSHOT`** (and related) — Alex-typed outputs referenced in **`dataset.csv` `DS_070` / `DS_071`**. |
| **`RAW.STANFORD`** | Legacy mirror (**~2** objects) — prefer **`SOURCE_PROD`** / **`TRANSFORM.STANFORD`** per baseline. |

### B1. Object inventory

- [ ] Run inventory script **ST-A** (`TRANSFORM.STANFORD`), **ST-B** (`SOURCE_PROD.STANFORD`), optional **ST-C** (`RAW.STANFORD`).
- [ ] Confirm which **`TRANSFORM.STANFORD`** objects exist vs **`stanford_transform`** / corridor investigation scripts (`scripts/corridor_1fact/sql/seda_grf25_stanford_h3_chain_investigation.sql`).

### B1.5 VARIANT — field presence vs documentation

**Operational note:** Run **ST-A → ST-B → ST-B2** before **ST-D**; if **ST-G** fails, confirm **`leaid` / `year`** paths in VARIANT from **ST-D** keys and adjust the query.

**Documented field sets (semantic, not automatic physical truth):**

1. **`sources.yml`** table descriptions for **`stanford_seda_admindist_parquet`**, **`stanford_seda_crosswalk_parquet`**, **`stanford_seda_county_parquet`** — list **expected VARIANT keys** (e.g. `sedaadmin`, `fips`, `avgrdall`, `sesavgall`, `year`, `leaid`, `geoid`, …).
2. **`dbt/seeds/stanford_seda_field_dictionary.csv`** — glossary for **`STANFORD_SEDA_*`** metrics / columns.
3. **Physical truth:** `OBJECT_KEYS(V)` on a **recent** sample row from each parquet table (**ST-D** in SQL script), plus **`INFORMATION_SCHEMA.COLUMNS`** (`V`, `FILE_NAME`).

- [ ] Run **ST-D**; diff keys vs **`sources.yml`** bullets and seed dictionary.
- [ ] Document **keys in Snowflake not in seed** (new MSCI/Stanford fields) and **keys in seed not present in sample** (sparse columns or file-type filter — pool vs annual vs long).

### B1.6 Uniques and grain

- [ ] **ST-E:** row counts; **ST-F:** `FILE_NAME` distribution (`%pool%`, `%annual%`, `%long%`) to validate file-mix assumptions in facts.
- [ ] **ST-G:** crosswalk **`leaid` × `year`** duplicate check (comment out or adjust keys if physical VARIANT differs; confirm via **ST-B2**).

### B2. Consumers

- [ ] pretium-ai-dbt: **`fact_stanford_*`**, **`stanford_schools_county`**, **`model_ai_risk_*`** education joins, **`feature_place_signals_*`** SEDA stub references.
- [ ] Corridor / H3: **`fact_stanford_seda_h3_r8_snapshot`** upstream chain (admindist + crosswalk).

### B3. Exit (Stanford)

- [ ] Smoke **`SOURCE_PROD.STANFORD`** tables; smoke **`TRANSFORM.STANFORD`** if non-empty.
- [ ] **`T-VENDOR-STANFORD-READY`** → `migrated` when B1–B2 + VARIANT key diff on file.

---

## Part C — Combined exit

- [ ] Update **`MIGRATION_LOG.md`** with inventory dates, Redfin interim vs prod decision, Stanford `TRANSFORM` deployment status, and blockers.
- [ ] Register sources in **pretiumdata-dbt-semantic-layer** when first models compile there.

**Exit criteria:** Dated CSV / worksheet exports for **RF-A–RF-E** (minimum) + **RF-F/RF-I** when used, and **ST-A–ST-G** (minimum **ST-D** keys for all three parquet families), all linked from **`MIGRATION_LOG.md`** or **`docs/migration/artifacts/`**; Redfin column parity vs cleaned models verified; Stanford VARIANT keys reconciled to **`sources.yml`** + **`stanford_seda_field_dictionary.csv`**; task rows flipped in **`MIGRATION_TASKS.md`**.
