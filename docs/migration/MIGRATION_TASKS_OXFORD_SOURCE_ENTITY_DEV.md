# Migration / build — Oxford Economics from `SOURCE_ENTITY.PRETIUM` → `TRANSFORM.DEV`

**Naming:** Oxford product is **WDMARCO** (not *WDMACRO*). `metric_id` prefix **`WDMARCO_`** matches `Indicator_code`.

**Owner:** Alex  
**Governing docs:** pretium-ai-dbt `design/final/DEPRECATION_MIGRATION_COMPLIANCE.md`, `docs/governance/OXFORD_ECONOMICS_P1_AND_DATASETS.md`  
**Physical + join contract:** pretium-ai-dbt `docs/vendors/amreg/OXFORD_SOURCE_ENTITY_PROFILE_AND_CROSSWALK_JOIN.md`  
**Repeatable CTAS (ref):** pretium-ai-dbt `scripts/sql/source_entity/materialize_ref_oxford_metro_cbsa_dev.sql`

**Task IDs (in `MIGRATION_TASKS.md`):**

| Task ID | Snowflake object | Status |
|---------|------------------|--------|
| **T-DEV-REF-OXFORD-METRO-CBSA** | `TRANSFORM.DEV.REF_OXFORD_METRO_CBSA` | `migrated` |
| **T-DEV-FACT-OXFORD-AMREG-QUARTERLY** | `TRANSFORM.DEV.FACT_OXFORD_AMREG_QUARTERLY` | `migrated` |
| **T-DEV-FACT-OXFORD-WDMARCO-QUARTERLY** | `TRANSFORM.DEV.FACT_OXFORD_WDMARCO_QUARTERLY` | `migrated` |

---

## §1.5 Snowflake verification (ref table)

- [x] **`REF_OXFORD_METRO_CBSA` present in `TRANSFORM.DEV`:** `SELECT COUNT(*) FROM TRANSFORM.DEV.REF_OXFORD_METRO_CBSA` → **302** rows (**2026-04-19**, `snowsql -c pretium`). **dbt:** `models/transform/dev/oxford/ref_oxford_metro_cbsa.sql` reads **`source('transform_dev_oxford_ref','oxford_cbsa_crosswalk')`** → `TRANSFORM.DEV.OXFORD_CBSA_CROSSWALK`. **Land** the table first: `docs/migration/sql/land_oxford_cbsa_crosswalk_transform_dev.sql` (one-time; may read `TRANSFORM_PROD` only inside that script, not in dbt). Emergency: pretium-ai-dbt `scripts/sql/source_entity/materialize_ref_oxford_metro_cbsa_dev.sql` then copy/rename to `OXFORD_CBSA_CROSSWALK` if needed.

---

## §0 Deliverables (build order)

1. **`REF_OXFORD_METRO_CBSA`** — [x] **dbt** `ref_oxford_metro_cbsa` from `TRANSFORM_PROD.REF.OXFORD_CBSA_CROSSWALK` + uniqueness tests on `(oxford_location_code, oxford_region_type)`.
2. **`FACT_OXFORD_AMREG_QUARTERLY`** — [x] **dbt** `fact_oxford_amreg_quarterly` view: `SOURCE_ENTITY.PRETIUM.AMREG` inner join ref; `Region_Type = 'MSA'`; `metric_id` = `AMREG_` || upper(`Indicator_code`); `date_reference` / `frequency_code` per profile §5. **Open:** governance `post_hook` parity with pretium-ai-dbt `fact_amreg_cbsa_economics` when Alex owns registry wiring.
3. **`FACT_OXFORD_WDMARCO_QUARTERLY`** — [x] **dbt** `fact_oxford_wdmarco_quarterly` view: national `geo_id = USA`, `metric_id` = `WDMARCO_` || upper(`Indicator_code`). **Open:** `DIM_METRIC` / `register_oxford_economics_metrics.sql` for full series catalog.

---

## §1 Source registration (pretium-ai-dbt → semantic layer)

- [x] pretium-ai-dbt `sources.yml` already declares Oxford / SOURCE_ENTITY paths (see pretium-ai-dbt grep `SOURCE_ENTITY.PRETIUM`).
- [x] **pretiumdata-dbt-semantic-layer:** `models/sources/sources_source_entity_pretium.yml` (`amreg`, `wdmarco`) + `models/sources/sources_transform_dev_oxford_ref.yml` (`oxford_cbsa_crosswalk` on **TRANSFORM.DEV**).

---

## §2 Staging / cleaned (optional thin layer)

- [ ] Staging: quoted identifiers → typed columns; null guards on `Year`, `Period`, `Data`, `Indicator_code`.
- [ ] Document **MSAD** exclusion or separate MSAD→CBSA rule before CBSA facts (see profile doc).

---

## §3 Facts — tests and smoke

- [ ] Grain: `NOT EXISTS` duplicates on `(date_reference, geo_id, metric_id, vendor_name)` (or project `unique_key`).
- [ ] Row-count sanity vs source (sample filters: one CBSA, one quarter).
- [ ] `SELECT 1` smoke in migration role.
- [ ] `DIM_METRIC` / `register_oxford_economics_metrics.sql` alignment for new `metric_id` prefix rules.

---

## §4 Exit

- [x] Flip **`T-DEV-REF-OXFORD-METRO-CBSA`** in `MIGRATION_TASKS.md` to **`migrated`** once Snowflake table exists (done **2026-04-19**); FACT rows stay **`pending`** until dbt models + builds land.
- [ ] Log full Oxford fact build dates and MSAD / legacy `fact_amreg_cbsa_economics` coexistence notes in **`MIGRATION_LOG.md`** when AMREG/WDMARCO facts ship.
