# Lineage registry (semantic-layer repo)

Registers **vendor → dataset → metrics / derived / engineered features → facts (dbt)** for objects that live under **`TRANSFORM.DEV`** and **`REFERENCE.*`**, without encoding that story only in `models/` path names.

**Contract:** Same key layout as **`pretium-ai-dbt/registry/lineage/README.md`** (`lineage_version: 1`). Realtor.com worked example: **`pretium-ai-dbt/registry/lineage/examples/vendor_realtor_com.lineage.yml`** (built from `docs/data_dictionaries/raw/realtor/realtor_metrics.txt` in that repo).

**This repo:**

| File | Register |
|------|----------|
| `corridor_lodes_h3_r8_lineage.yml` | LEHD / LODES corridor employment-center **FACT_** chain in `models/transform/dev/lodes/`. |

dbt `schema.yml` descriptions under `lodes/` link here for the LODES slice.
