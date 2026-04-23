# Anchor Screener: Source Discovery (Feb 2026)

**Purpose:** Document actual data sources vs. model expectations. Used to fix column/table mismatches.

---

## Summary

| Source | Row Count | Status | Notes |
|--------|-----------|--------|-------|
| housing_hou_pricing_all_ts | 1.9B | ✅ | Cherre 1.9B, Markerr 975K, Realtor 182K, Yardi 132K — **No Redfin 2025+** |
| household_hh_demographics_all_ts | 40K | ✅ | CPS age bins only; ACS/household formation 0 rows |
| household_hh_labor_all_ts | 296K | ✅ | CPS metrics (unemployment, labor force, wages). **QCEW missing** — run `qcew_county` → `fact_household_labor_qcew_cbsa` for NAICS industry breakdown. |
| fact_place_plc_education_all_ts | 45K | ⚠️ | EDUCATION_K12_SCHOOL_COUNT only — **not a quality score** |
| fact_place_plc_safety_all_ts | 364K | ✅ | Markerr crime indices |
| fact_place_major_retailers | varies | ✅ | Overture `overture_places_us_retailers` (when OVERTURE_MAPS share exists) |
| anchor_loans.deals | exists | ⚠️ | **PROJECT_STATUS** (not DECISION_STATUS), **no CBSA column** |

**Zonda:** Use `DS_SOURCE_PROD_TPANALYTICS.TPANALYTICS_SHARE.ZONDA_BTR_COMPREHENSIVE` via `zonda_btr_projects` (2,787 projects, 434 builders with lat/lon). `v_anchor_zonda_comps` now reads from `ref(zonda_btr_projects)`.

**QCEW still needed:** CPS only; no NAICS industry codes. Complete: `qcew_county` → `fact_household_labor_qcew_cbsa`; union into `household_hh_labor_all_ts`. Template expects `QCEW_NAICS_{code}_EMPLOYMENT`.

---

## Column Mismatches Fixed

| Model | Expected | Actual | Fix |
|-------|----------|--------|-----|
| stg_anchor_deals, v_anchor_deal_screener | decision_status | project_status | `anchor_deals_status_column: project_status` |
| stg_anchor_deals, v_anchor_deal_screener | d.cbsa_code, d.id_cbsa | (none) | Use only `r.resolved_cbsa` (schema-safe) |
| stg_housing_metrics_zip, price_zip | REDFIN_MEDIAN_SALE_PRICE | (no Redfin 2025+) | Priority: Cherre sale/list, Realtor listing |

---

## Semantic Mismatches (Not Fixed)

| Metric | Model Expects | Actual Data |
|--------|---------------|-------------|
| School district rank | Quality/rank score | K12 school count |
| Peak UPB | Time-series peak | Snapshot loan_amount |
| Months of supply | Single metric | Pattern matches multiple |

---

## Vars Set for Discovery

```yaml
# dbt_project.yml
anchor_deals_status_column: 'project_status'
anchor_deals_funded_value: 'funded'
# CBSA: models use r.resolved_cbsa only (no deal column)
```

---

## Missing Data Sources: Need vs Have vs Fix

| Metric | Need | Have | Fix |
|--------|------|------|-----|
| **School scores** | Cotality (education quality scores) | School count only (not rank/score) | `place_cotality_available: true` + load Cotality data |
| **Major retailers** | Overture Maps POI | `overture_places_us_retailers` → `fact_place_major_retailers` | OVERTURE_MAPS__PLACES.CARTO.PLACE share |
| **Labor / industries** | QCEW (BLS employment by NAICS) | CPS labor (wrong source) | `anchor_use_qcew_top3: true` + load QCEW data. Also Markerr labor for employment. |
| **Builders within 5 mi** | Zonda builder locations (lat/lon) | Zonda BTR comps exist; no builder registry | Create `ref_builder_locations` from Zonda or separate source |
| **HBF Market Score** | Derived from Zonda (starts, closings, absorption) | External table doesn't exist | Build `capital_cap_economy_all_ts` using Zonda as input |
| **Zonda BTR comps (5.2)** | BTR project comparables | `zonda_btr_projects` from `DS_SOURCE_PROD_TPANALYTICS.TPANALYTICS_SHARE.ZONDA_BTR_COMPREHENSIVE` | `v_anchor_zonda_comps` reads `ref(zonda_btr_projects)`; 2,787 projects, 434 builders with lat/lon |
| **Starts vs Closings chart** | Zonda starts/closings (SFR/BTR) | MF fallback (wrong product) | `zonda_starts_closings_available: true` + `anchor_starts_closings_from_zonda: true` + load `DS_TPANALYTICS.ZONDA.ZONDA_STARTS_CLOSINGS` |

### DEALS Column Mismatches (Resolved)

| Old name | Actual | Action taken |
|----------|--------|--------------|
| decision_status | PROJECT_STATUS | `anchor_deals_status_column: project_status` |
| property_zip | ZIP_CODE | Models use zip_code |
| cbsa_code | Not in table | Derive from ZIP via `r.resolved_cbsa` |

**Production:** Load vendors or accept NULL/0 for metrics until sources are wired.
