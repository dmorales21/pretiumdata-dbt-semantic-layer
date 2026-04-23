# US Census Bureau — LEHD — Data Guidance

⚠️ **INTERNAL — contract and operational context**

**Intake bundle:** `docs/vendors/lehd/` (machine column inventory + this narrative).  
**Canonical vendor hub:** `docs/vendor/lehd/` (dictionary + structured stubs).

---

## Catalog snapshot (seeds/reference/catalog/vendor.csv)

| Field | Value |
|-------|-------|
| **vendor_id** | `VND_039` |
| **vendor_code** | `lehd` |
| **vendor_label** | US Census Bureau — LEHD |
| **definition** | LEHD LODES origin-destination employment statistics at block grain covering jobs by industry and worker characteristics |
| **data_type** | administrative |
| **refresh_cadence** | annual |
| **contract_status** | active |
| **source_schema** | `RAW.LEHD` |
| **data_share_type** | s3 |
| **vertical_codes** | — |

**Primary migration doc (inventory):** [migration/MIGRATION_TASKS_TRANSFORM_BPS_CENSUS_BLS_LODES.md](../migration/MIGRATION_TASKS_TRANSFORM_BPS_CENSUS_BLS_LODES.md)

---

## Vendor methodology (full text from `docs/vendor/lehd/lehd.md`)

**Catalog row:** `vendor_id` = `VND_039` in `seeds/reference/catalog/vendor.csv`.

## 1. Identity

LEHD LODES origin-destination employment statistics at block grain covering jobs by industry and worker characteristics

## 2. Contract (catalog)

| Attribute | Value |
|-----------|-------|
| **data_type** | administrative |
| **refresh_cadence** | annual |
| **contract_status** | active |
| **source_schema** | `RAW.LEHD` |
| **is_active** | TRUE |
| **data_share_type** | s3 |
| **is_motherduck_served** | FALSE |
| **vertical_codes** | — |

## 3. Read path (methodology)

1. Prefer **Jon silver** on **TRANSFORM** (vendor schema, e.g. `TRANSFORM.ZILLOW`, `TRANSFORM.MARKERR`) or **`TRANSFORM.FACT`** when the object exists and is vetted (see [MIGRATION_RULES.md](../migration/MIGRATION_RULES.md)).
2. Otherwise use the catalog **`source_schema`** (`RAW.*`, `SOURCE_ENTITY.*`, `SOURCE_SNOW.*`, etc.) and declare reads in `models/sources/*.yml`.
3. **Alex dbt** implements **`TRANSFORM.DEV`** read-throughs and typed facts under `models/transform/dev/` where applicable.
4. **REFERENCE.CATALOG** (`metric`, `dataset`, `bridge_product_type_metric`) must align with real column names after `DESCRIBE` / lineage — see [METRIC_INTAKE_CHECKLIST.md](../migration/METRIC_INTAKE_CHECKLIST.md).

## 4. Grain and concepts

See [VENDOR_CONCEPT_COVERAGE_MATRIX.md](../migration/VENDOR_CONCEPT_COVERAGE_MATRIX.md) for **`lehd`** × concept × dataset gaps and stretch mappings.

## 5. Field dictionary (machine-readable)

| File | Description |
|------|-------------|
| `dictionary.csv` | Column/metric-level rows (extend per inventory). |
| `dictionary.yaml` | Vendor-level metadata + empty `fields` list until filled. |

## 6. Migration and QA

Primary task / vet doc: [`migration/MIGRATION_TASKS_TRANSFORM_BPS_CENSUS_BLS_LODES.md`](../migration/MIGRATION_TASKS_TRANSFORM_BPS_CENSUS_BLS_LODES.md)

## 7. Related rules

- [OPERATING_MODEL.md](../OPERATING_MODEL.md)
- [rules/TRANSFORM_VENDOR_DESIGN_PRINCIPLES.md](../rules/TRANSFORM_VENDOR_DESIGN_PRINCIPLES.md)

---

## Physical metrics summary (`vendor_metrics.csv`)

| Metric | Value |
|--------|-------|
| **Unique physical columns** | 93 |
| **Rows pointing at TRANSFORM.DEV / DEV paths** | 93 |
| **Raw catalog metrics (metric.csv rows for this vendor)** | 96 |

Long-form facts collapse many catalog `metric_id` values onto one `snowflake_column` (for example `VALUE` / `METRIC_VALUE`); use **`seeds/reference/catalog/metric.csv`** (this repo) or pretium-ai-dbt merged `metric.csv` for the full metric registry.

---

## Concept mapping (physical rows, first 50)

| metric_id | concept_code | domain | direction | table_path | snowflake_column |
|-----------|--------------|--------|-----------|------------|------------------|
| LEHD_MAN_918D6D77E5 | pipeline | place | neutral | `TRANSFORM.DEV.FACT_LODES_H3R8_WORKPLACE_GRAVITY` | `COMMUTER_BG_COUNT` |
| LEHD_MAN_FCA5E8063F | pipeline | place | neutral | `TRANSFORM.DEV.FACT_LODES_H3R8_WORKPLACE_GRAVITY` | `JOBS_GOODS` |
| LEHD_MAN_F21105DB5B | pipeline | place | neutral | `TRANSFORM.DEV.FACT_LODES_H3R8_WORKPLACE_GRAVITY` | `JOBS_SE01` |
| LEHD_MAN_AA69426FFA | pipeline | place | neutral | `TRANSFORM.DEV.FACT_LODES_H3R8_WORKPLACE_GRAVITY` | `JOBS_SE02` |
| LEHD_MAN_F0492731D5 | pipeline | place | neutral | `TRANSFORM.DEV.FACT_LODES_H3R8_WORKPLACE_GRAVITY` | `JOBS_SE03` |
| LEHD_MAN_49FCEAEEFE | pipeline | place | neutral | `TRANSFORM.DEV.FACT_LODES_H3R8_WORKPLACE_GRAVITY` | `JOBS_SERVICES` |
| LEHD_MAN_F0DF634413 | pipeline | place | neutral | `TRANSFORM.DEV.FACT_LODES_H3R8_WORKPLACE_GRAVITY` | `JOBS_TRADE_TRANSPORT` |
| LEHD_MAN_FD64D8AD | pipeline | place | neutral | `TRANSFORM.DEV.FACT_LODES_H3R8_WORKPLACE_GRAVITY` | `JOB_INFLOW_TOTAL` |
| LEHD_MAN_8404547107 | pipeline | place | neutral | `TRANSFORM.DEV.FACT_LODES_H3R8_WORKPLACE_GRAVITY` | `LOG_JOB_INFLOW` |
| LEHD_MAN_7CB095A4A5 | pipeline | place | neutral | `TRANSFORM.DEV.FACT_LODES_H3R8_WORKPLACE_GRAVITY` | `SE03_SHARE` |
| LEHD_MAN_76FF5106AB | pipeline | place | neutral | `TRANSFORM.DEV.FACT_LODES_H3R8_WORKPLACE_GRAVITY` | `SI01_SHARE` |
| LEHD_MAN_783578EAA7 | pipeline | place | neutral | `TRANSFORM.DEV.FACT_LODES_H3R8_WORKPLACE_GRAVITY` | `SI03_SHARE` |
| LEHD_MAN_54E1382552 | pipeline | place | neutral | `TRANSFORM.DEV.FACT_LODES_NEAREST_CENTER_H3_R8_ANNUAL` | `DIST_NEAREST_ANY_CENTER` |
| LEHD_MAN_73F966A5D1 | pipeline | place | neutral | `TRANSFORM.DEV.FACT_LODES_NEAREST_CENTER_H3_R8_ANNUAL` | `DIST_NEAREST_GOODS_PRODUCING` |
| LEHD_MAN_5D4BBE4FEE | employment | place | neutral | `TRANSFORM.DEV.FACT_LODES_NEAREST_CENTER_H3_R8_ANNUAL` | `DIST_NEAREST_HIGH_WAGE_OFFICE` |
| LEHD_MAN_56B305765C | pipeline | place | neutral | `TRANSFORM.DEV.FACT_LODES_NEAREST_CENTER_H3_R8_ANNUAL` | `DIST_NEAREST_MIXED_URBAN` |
| LEHD_MAN_DCD4BC5B47 | pipeline | place | neutral | `TRANSFORM.DEV.FACT_LODES_NEAREST_CENTER_H3_R8_ANNUAL` | `DIST_NEAREST_PROFESSIONAL_CENTER` |
| LEHD_MAN_809816E092 | pipeline | place | neutral | `TRANSFORM.DEV.FACT_LODES_NEAREST_CENTER_H3_R8_ANNUAL` | `DIST_NEAREST_SUBURBAN_COMMERCIAL` |
| LEHD_MAN_0885E35A39 | pipeline | place | neutral | `TRANSFORM.DEV.FACT_LODES_NEAREST_CENTER_H3_R8_ANNUAL` | `DIST_NEAREST_URBAN_CENTER` |
| LEHD_MAN_565906F960 | pipeline | place | neutral | `TRANSFORM.DEV.FACT_LODES_NEAREST_CENTER_H3_R8_ANNUAL` | `STRENGTH_NEAREST_ANY_CENTER` |
| LEHD_MAN_1BD0F43949 | employment | place | neutral | `TRANSFORM.DEV.FACT_LODES_NEAREST_CENTER_H3_R8_ANNUAL` | `STRENGTH_NEAREST_HIGH_WAGE_OFFICE` |
| LEHD_MAN_6334EB350E | pipeline | place | neutral | `TRANSFORM.DEV.FACT_LODES_NEAREST_CENTER_H3_R8_ANNUAL` | `STRENGTH_NEAREST_MIXED_URBAN` |
| LEHD_MAN_E20A4A9935 | pipeline | place | neutral | `TRANSFORM.DEV.FACT_LODES_NEAREST_CENTER_H3_R8_ANNUAL` | `STRENGTH_NEAREST_SUBURBAN_COMMERCIAL` |
| LEHD_MAN_3528B01991 | pipeline | place | neutral | `TRANSFORM.DEV.FACT_LODES_NEAREST_CENTER_H3_R8_ANNUAL` | `STRENGTH_NEAREST_URBAN_CENTER` |
| LEHD_MAN_6FD625E89C | pipeline | place | neutral | `TRANSFORM.DEV.FACT_LODES_OD_BG` | `JOBS_AGE_SA01` |
| LEHD_MAN_C56FAA9573 | pipeline | place | neutral | `TRANSFORM.DEV.FACT_LODES_OD_BG` | `JOBS_AGE_SA02` |
| LEHD_MAN_A8DD95A115 | pipeline | place | neutral | `TRANSFORM.DEV.FACT_LODES_OD_BG` | `JOBS_AGE_SA03` |
| LEHD_MAN_FC7FCD6D35 | pipeline | place | neutral | `TRANSFORM.DEV.FACT_LODES_OD_BG` | `JOBS_EARNINGS_SE01` |
| LEHD_MAN_B60043777A | pipeline | place | neutral | `TRANSFORM.DEV.FACT_LODES_OD_BG` | `JOBS_EARNINGS_SE02` |
| LEHD_MAN_3E4254EDEF | pipeline | place | neutral | `TRANSFORM.DEV.FACT_LODES_OD_BG` | `JOBS_EARNINGS_SE03` |
| LEHD_MAN_5FEF6E7E58 | pipeline | place | neutral | `TRANSFORM.DEV.FACT_LODES_OD_BG` | `JOBS_INDUSTRY_SI01` |
| LEHD_MAN_7D31BA22FE | pipeline | place | neutral | `TRANSFORM.DEV.FACT_LODES_OD_BG` | `JOBS_INDUSTRY_SI02` |
| LEHD_MAN_56F55737B4 | pipeline | place | neutral | `TRANSFORM.DEV.FACT_LODES_OD_BG` | `JOBS_INDUSTRY_SI03` |
| MET_007 | employment | place | positive | `TRANSFORM.DEV.FACT_LODES_OD_BG` | `JOBS_TOTAL` |
| LEHD_MAN_E174ACF91E | pipeline | place | neutral | `TRANSFORM.DEV.FACT_LODES_OD_COUNTY_ANNUAL` | `BG_PAIR_COUNT` |
| LEHD_MAN_0F36EF71C2 | pipeline | place | neutral | `TRANSFORM.DEV.FACT_LODES_OD_COUNTY_ANNUAL` | `JOBS_AGE_SA01` |
| LEHD_MAN_E8ED032C07 | pipeline | place | neutral | `TRANSFORM.DEV.FACT_LODES_OD_COUNTY_ANNUAL` | `JOBS_AGE_SA02` |
| LEHD_MAN_D20CFBC30C | pipeline | place | neutral | `TRANSFORM.DEV.FACT_LODES_OD_COUNTY_ANNUAL` | `JOBS_AGE_SA03` |
| LEHD_MAN_31D06CBCD1 | pipeline | place | neutral | `TRANSFORM.DEV.FACT_LODES_OD_COUNTY_ANNUAL` | `JOBS_EARNINGS_SE01` |
| LEHD_MAN_12FEF9F36B | pipeline | place | neutral | `TRANSFORM.DEV.FACT_LODES_OD_COUNTY_ANNUAL` | `JOBS_EARNINGS_SE02` |
| LEHD_MAN_7788570F47 | pipeline | place | neutral | `TRANSFORM.DEV.FACT_LODES_OD_COUNTY_ANNUAL` | `JOBS_EARNINGS_SE03` |
| LEHD_MAN_8ED6234B88 | pipeline | place | neutral | `TRANSFORM.DEV.FACT_LODES_OD_COUNTY_ANNUAL` | `JOBS_INDUSTRY_SI01` |
| LEHD_MAN_F770169DF6 | pipeline | place | neutral | `TRANSFORM.DEV.FACT_LODES_OD_COUNTY_ANNUAL` | `JOBS_INDUSTRY_SI02` |
| LEHD_MAN_697624A741 | pipeline | place | neutral | `TRANSFORM.DEV.FACT_LODES_OD_COUNTY_ANNUAL` | `JOBS_INDUSTRY_SI03` |
| LEHD_MAN_6C47AEEA93 | pipeline | place | neutral | `TRANSFORM.DEV.FACT_LODES_OD_COUNTY_ANNUAL` | `JOBS_TOTAL` |
| LEHD_MAN_17A4A63533 | pipeline | place | neutral | `TRANSFORM.DEV.FACT_LODES_OD_COUNTY_ANNUAL` | `SA01_SHARE` |
| LEHD_MAN_6066DF6329 | pipeline | place | neutral | `TRANSFORM.DEV.FACT_LODES_OD_COUNTY_ANNUAL` | `SE03_SHARE` |
| LEHD_MAN_067BDAD166 | pipeline | place | neutral | `TRANSFORM.DEV.FACT_LODES_OD_H3_R8_ANNUAL` | `BG_PAIR_COUNT` |
| LEHD_MAN_52101C0245 | pipeline | place | neutral | `TRANSFORM.DEV.FACT_LODES_OD_H3_R8_ANNUAL` | `JOBS_AGE_SA01` |
| LEHD_MAN_AC546F533F | pipeline | place | neutral | `TRANSFORM.DEV.FACT_LODES_OD_H3_R8_ANNUAL` | `JOBS_AGE_SA02` |

*(43 additional rows in `vendor_metrics.csv`.)*


---

## Join keys, refresh detection, limitations

**[UNKNOWN — needs profiling]** unless the embedded methodology above states otherwise. Align postal vs ZCTA, CBSA vintages, and agency attribution (especially Cybersyn-sourced agency tables) before production joins.

---

## Changelog

| Date | Commit | Notes |
|------|--------|-------|
| 2026-04-23 | `[auto]` | Full intake regeneration via `scripts/docs/generate_all_vendors_intake_full.py`. |
