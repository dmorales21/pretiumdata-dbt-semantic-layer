# Stanford SEDA — Data Guidance

⚠️ **INTERNAL — contract and operational context**

**Intake bundle:** `docs/vendors/stanford/` (machine column inventory + this narrative).  
**Canonical vendor hub:** `docs/vendor/stanford/` (dictionary + structured stubs).

---

## Catalog snapshot (seeds/reference/catalog/vendor.csv)

| Field | Value |
|-------|-------|
| **vendor_id** | `VND_051` |
| **vendor_code** | `stanford` |
| **vendor_label** | Stanford SEDA |
| **definition** | Stanford Education Data Archive county and district achievement SES and enrollment measures on SOURCE_PROD.STANFORD parquet |
| **data_type** | administrative |
| **refresh_cadence** | annual |
| **contract_status** | active |
| **source_schema** | `SOURCE_PROD.STANFORD` |
| **data_share_type** | s3 |
| **vertical_codes** | — |

**Primary migration doc (inventory):** — (see `docs/vendor/0_inventory/vendors_inventory.csv`)

---

## Vendor methodology (full text from `docs/vendor/stanford/stanford.md`)

**Catalog row:** `vendor_id` = `VND_051` in `seeds/reference/catalog/vendor.csv`.

## 1. Identity

Stanford Education Data Archive county and district achievement SES and enrollment measures on SOURCE_PROD.STANFORD parquet

## 2. Contract (catalog)

| Attribute | Value |
|-----------|-------|
| **data_type** | administrative |
| **refresh_cadence** | annual |
| **contract_status** | active |
| **source_schema** | `SOURCE_PROD.STANFORD` |
| **data_share_type** | s3 |

## 3. Read path

See [OPERATING_MODEL.md](../OPERATING_MODEL.md) and [migration/MIGRATION_RULES.md](../migration/MIGRATION_RULES.md).



---

## Physical metrics summary (`vendor_metrics.csv`)

| Metric | Value |
|--------|-------|
| **Unique physical columns** | 60 |
| **Rows pointing at TRANSFORM.DEV / DEV paths** | 60 |
| **Raw catalog metrics (metric.csv rows for this vendor)** | 61 |

Long-form facts collapse many catalog `metric_id` values onto one `snowflake_column` (for example `VALUE` / `METRIC_VALUE`); use **`seeds/reference/catalog/metric.csv`** (this repo) or pretium-ai-dbt merged `metric.csv` for the full metric registry.

---

## Concept mapping (physical rows, first 50)

| metric_id | concept_code | domain | direction | table_path | snowflake_column |
|-----------|--------------|--------|-----------|------------|------------------|
| STANFORD_MAN_A49F000A | school_quality | place | positive | `TRANSFORM.DEV.CONCEPT_SCHOOL_QUALITY_MARKET_ANNUAL` | `school_quality_current` |
| STANFORD_DEV_SCHOOLS_COUNTY_AVGRD | education | household | neutral | `TRANSFORM.DEV.FACT_STANFORD_SCHOOLS_COUNTY` | `AVGRD_ALL` |
| STANFORD_DEV_SCHOOLS_COUNTY_GAP_BLK_WHT | education | household | negative | `TRANSFORM.DEV.FACT_STANFORD_SCHOOLS_COUNTY` | `GAP_BLK_WHT` |
| STANFORD_DEV_SCHOOLS_COUNTY_GAP_HSP_WHT | education | household | negative | `TRANSFORM.DEV.FACT_STANFORD_SCHOOLS_COUNTY` | `GAP_HSP_WHT` |
| STANFORD_DEV_SCHOOLS_COUNTY_INCOME | income | household | positive | `TRANSFORM.DEV.FACT_STANFORD_SCHOOLS_COUNTY` | `LN_INC50_ALL` |
| STANFORD_DEV_SCHOOLS_COUNTY_PCT_ASIAN | population | household | neutral | `TRANSFORM.DEV.FACT_STANFORD_SCHOOLS_COUNTY` | `PCT_ASIAN` |
| STANFORD_DEV_SCHOOLS_COUNTY_BA_PLUS | income | household | positive | `TRANSFORM.DEV.FACT_STANFORD_SCHOOLS_COUNTY` | `PCT_BA_PLUS` |
| STANFORD_DEV_SCHOOLS_COUNTY_PCT_BLACK | population | household | neutral | `TRANSFORM.DEV.FACT_STANFORD_SCHOOLS_COUNTY` | `PCT_BLACK` |
| STANFORD_DEV_SCHOOLS_COUNTY_ECD | income | household | negative | `TRANSFORM.DEV.FACT_STANFORD_SCHOOLS_COUNTY` | `PCT_ECON_DISADVANTAGED` |
| STANFORD_DEV_SCHOOLS_COUNTY_FRL | income | household | negative | `TRANSFORM.DEV.FACT_STANFORD_SCHOOLS_COUNTY` | `PCT_FREE_REDUCED_LUNCH` |
| STANFORD_DEV_SCHOOLS_COUNTY_PCT_HISPANIC | population | household | neutral | `TRANSFORM.DEV.FACT_STANFORD_SCHOOLS_COUNTY` | `PCT_HISPANIC` |
| STANFORD_DEV_SCHOOLS_COUNTY_POVERTY | income | household | negative | `TRANSFORM.DEV.FACT_STANFORD_SCHOOLS_COUNTY` | `PCT_POVERTY` |
| STANFORD_DEV_SCHOOLS_COUNTY_PCT_RURAL | population | household | neutral | `TRANSFORM.DEV.FACT_STANFORD_SCHOOLS_COUNTY` | `PCT_RURAL` |
| STANFORD_DEV_SCHOOLS_COUNTY_PCT_SUBURB | population | household | neutral | `TRANSFORM.DEV.FACT_STANFORD_SCHOOLS_COUNTY` | `PCT_SUBURB` |
| STANFORD_DEV_SCHOOLS_COUNTY_PCT_URBAN | population | household | neutral | `TRANSFORM.DEV.FACT_STANFORD_SCHOOLS_COUNTY` | `PCT_URBAN` |
| STANFORD_DEV_SCHOOLS_COUNTY_PCT_WHITE | population | household | neutral | `TRANSFORM.DEV.FACT_STANFORD_SCHOOLS_COUNTY` | `PCT_WHITE` |
| STANFORD_DEV_SCHOOLS_COUNTY_SES | education | household | neutral | `TRANSFORM.DEV.FACT_STANFORD_SCHOOLS_COUNTY` | `SES_AVG_ALL` |
| STANFORD_DEV_SCHOOLS_COUNTY_ENROLLMENT | population | household | neutral | `TRANSFORM.DEV.FACT_STANFORD_SCHOOLS_COUNTY` | `TOTAL_ENROLLMENT` |
| STANFORD_FAM_AD8DF46EDCDF | education | household | neutral | `TRANSFORM.DEV.FACT_STANFORD_SCHOOLS_H3_R8_SNAPSHOT` | `AVG_STUDENTS_PER_TEACHER` |
| STANFORD_FAM_91338E01E24D | education | household | neutral | `TRANSFORM.DEV.FACT_STANFORD_SCHOOLS_H3_R8_SNAPSHOT` | `ELEMENTARY_COUNT` |
| STANFORD_FAM_210380B3D057 | education | household | neutral | `TRANSFORM.DEV.FACT_STANFORD_SCHOOLS_H3_R8_SNAPSHOT` | `ELEMENTARY_SCORE_AVG` |
| STANFORD_FAM_354EBCCD9B13 | education | household | neutral | `TRANSFORM.DEV.FACT_STANFORD_SCHOOLS_H3_R8_SNAPSHOT` | `ELEMENTARY_SCORE_MAX` |
| STANFORD_FAM_810AD6F2A78A | education | household | neutral | `TRANSFORM.DEV.FACT_STANFORD_SCHOOLS_H3_R8_SNAPSHOT` | `HIGH_SCORE_AVG` |
| STANFORD_FAM_CB8AC8833417 | education | household | neutral | `TRANSFORM.DEV.FACT_STANFORD_SCHOOLS_H3_R8_SNAPSHOT` | `MIDDLE_SCORE_AVG` |
| STANFORD_FAM_5927DFCB3291 | education | household | neutral | `TRANSFORM.DEV.FACT_STANFORD_SCHOOLS_H3_R8_SNAPSHOT` | `PRIVATE_SCORE_AVG` |
| STANFORD_FAM_A3ADBA3FE994 | education | household | neutral | `TRANSFORM.DEV.FACT_STANFORD_SCHOOLS_H3_R8_SNAPSHOT` | `PUBLIC_SCORE_AVG` |
| STANFORD_FAM_7D7122F6EF13 | education | household | neutral | `TRANSFORM.DEV.FACT_STANFORD_SCHOOLS_H3_R8_SNAPSHOT` | `SCHOOL_COUNT` |
| STANFORD_FAM_8E0EAA8CE2FA | education | household | neutral | `TRANSFORM.DEV.FACT_STANFORD_SCHOOLS_H3_R8_SNAPSHOT` | `SCHOOL_SCORE_AVG` |
| STANFORD_FAM_F3D9208223D8 | education | household | neutral | `TRANSFORM.DEV.FACT_STANFORD_SCHOOLS_H3_R8_SNAPSHOT` | `SCHOOL_SCORE_MAX` |
| STANFORD_FAM_DF6511DDF11D | education | household | neutral | `TRANSFORM.DEV.FACT_STANFORD_SEDA_COUNTY_SNAPSHOT` | `GAP_BLK_WHT` |
| STANFORD_FAM_0D2E16D19305 | education | household | neutral | `TRANSFORM.DEV.FACT_STANFORD_SEDA_COUNTY_SNAPSHOT` | `GAP_HSP_WHT` |
| STANFORD_FAM_B9AAE5E7D3ED | education | household | neutral | `TRANSFORM.DEV.FACT_STANFORD_SEDA_COUNTY_SNAPSHOT` | `LN_INC50_ALL` |
| STANFORD_FAM_BB41CB4D0145 | education | household | neutral | `TRANSFORM.DEV.FACT_STANFORD_SEDA_COUNTY_SNAPSHOT` | `PCT_ASIAN` |
| STANFORD_FAM_04AC501538EE | education | household | neutral | `TRANSFORM.DEV.FACT_STANFORD_SEDA_COUNTY_SNAPSHOT` | `PCT_BA_PLUS` |
| STANFORD_FAM_1421396C4278 | education | household | neutral | `TRANSFORM.DEV.FACT_STANFORD_SEDA_COUNTY_SNAPSHOT` | `PCT_BLACK` |
| STANFORD_FAM_2D48126413CD | education | household | neutral | `TRANSFORM.DEV.FACT_STANFORD_SEDA_COUNTY_SNAPSHOT` | `PCT_ECON_DISADVANTAGED` |
| STANFORD_FAM_9E55622E0321 | education | household | neutral | `TRANSFORM.DEV.FACT_STANFORD_SEDA_COUNTY_SNAPSHOT` | `PCT_FREE_REDUCED_LUNCH` |
| STANFORD_FAM_DE0B504DC754 | education | household | neutral | `TRANSFORM.DEV.FACT_STANFORD_SEDA_COUNTY_SNAPSHOT` | `PCT_HISPANIC` |
| STANFORD_FAM_999865BF8EFF | education | household | neutral | `TRANSFORM.DEV.FACT_STANFORD_SEDA_COUNTY_SNAPSHOT` | `PCT_POVERTY` |
| STANFORD_FAM_759868CE9A9B | education | household | neutral | `TRANSFORM.DEV.FACT_STANFORD_SEDA_COUNTY_SNAPSHOT` | `PCT_RURAL` |
| STANFORD_FAM_A0C35F050519 | education | household | neutral | `TRANSFORM.DEV.FACT_STANFORD_SEDA_COUNTY_SNAPSHOT` | `PCT_SUBURB` |
| STANFORD_FAM_7B2FE5BE649E | education | household | neutral | `TRANSFORM.DEV.FACT_STANFORD_SEDA_COUNTY_SNAPSHOT` | `PCT_URBAN` |
| STANFORD_FAM_5D7F3F4302D7 | education | household | neutral | `TRANSFORM.DEV.FACT_STANFORD_SEDA_COUNTY_SNAPSHOT` | `PCT_WHITE` |
| STANFORD_FAM_4864429A4525 | education | household | neutral | `TRANSFORM.DEV.FACT_STANFORD_SEDA_COUNTY_SNAPSHOT` | `SCHOOL_SCORE_AVG` |
| STANFORD_FAM_E5EA0B0A38DF | education | household | neutral | `TRANSFORM.DEV.FACT_STANFORD_SEDA_COUNTY_SNAPSHOT` | `SCHOOL_SCORE_QUINTILE` |
| STANFORD_FAM_8AD978F41D37 | education | household | neutral | `TRANSFORM.DEV.FACT_STANFORD_SEDA_COUNTY_SNAPSHOT` | `SES_AVG_ALL` |
| STANFORD_FAM_0E071825237F | education | household | neutral | `TRANSFORM.DEV.FACT_STANFORD_SEDA_COUNTY_SNAPSHOT` | `TOTAL_ENROLLMENT` |
| STANFORD_FAM_E1BE527996BE | education | household | neutral | `TRANSFORM.DEV.FACT_STANFORD_SEDA_H3_R8_SNAPSHOT` | `DISTRICT_COUNT` |
| STANFORD_FAM_AFD6B028DB93 | education | household | neutral | `TRANSFORM.DEV.FACT_STANFORD_SEDA_H3_R8_SNAPSHOT` | `GAP_BLK_WHT` |
| STANFORD_FAM_7975A05132D5 | education | household | neutral | `TRANSFORM.DEV.FACT_STANFORD_SEDA_H3_R8_SNAPSHOT` | `GAP_HSP_WHT` |

*(10 additional rows in `vendor_metrics.csv`.)*


---

## Join keys, refresh detection, limitations

**[UNKNOWN — needs profiling]** unless the embedded methodology above states otherwise. Align postal vs ZCTA, CBSA vintages, and agency attribution (especially Cybersyn-sourced agency tables) before production joins.

---

## Changelog

| Date | Commit | Notes |
|------|--------|-------|
| 2026-04-23 | `[auto]` | Full intake regeneration via `scripts/docs/generate_all_vendors_intake_full.py`. |
