# Ranked backlog — concept → missing MET slug → table_path / derived graph

**Owner:** Alex (catalog) / DS–DE (execution)  
**Purpose:** Single ordered queue for **new `MET_*` definitions**, **concept reassignment fixes**, **`metric_derived` graphs**, and **concept mart** work. Rank reflects **semantic-layer unblockers first** (wrong `concept_code`, zero coverage), then **SERVING bundle gaps**, then **bulk promotion** of already-registered observe rows.

**Sources of truth (this repo):** `seeds/reference/catalog/concept.csv`, `metric.csv`, `metric_derived.csv`, `metric_derived_input.csv`, `models/transform/dev/concept/*.sql`, [`SERVING_DEMO_METRICS_CATALOG_MAP.md`](../reference/SERVING_DEMO_METRICS_CATALOG_MAP.md), [`CONCEPT_VENDOR_METRIC_INTEGRATION_BACKLOG.md`](./CONCEPT_VENDOR_METRIC_INTEGRATION_BACKLOG.md).

**Ranking rules (high → low):**

1. **P0** — Wrong or missing `concept_code` on an existing physical column (blocks correct concept assignment KPIs and DS joins).
2. **P1** — **Zero** active `MET_*` for an active `concept_code`, or **no concept mart** while SERVING / IC expects a market spine.
3. **P2** — SERVING population slugs still **not representable** as a `MET_*` or **`metric_derived`** row.
4. **P3** — **Promotion** (`data_status_code`: `under_review` → `active`) and contract narrowing for large observe families.

Snowflake KPIs: `scripts/sql/validation/catalog_concept_metric_assignment_coverage.sql`, `scripts/sql/validation/catalog_metric_registration_coverage.sql`.

---

## Ranked work items

| Rank | Tier | Concept | Missing MET slug (proposed) | Type | Suggested `table_path` / derived graph | Notes |
|-----:|------|---------|------------------------------|------|----------------------------------------|--------|
| 1 | P0 | `dscr` | *(re-register existing)* `rca_mf_debt_h3_r8_monthly_dscr_count` | Reassign | `TRANSFORM.DEV.FACT_RCA_MF_DEBT_H3_R8_MONTHLY` · `DSCR_COUNT` | Today registered under `pipeline`; move to `dscr` and align `metric_code` / definition with IC. |
| 2 | P0 | `dscr` | *(re-register existing)* `rca_mf_debt_h3_r8_monthly_median_dscr` | Reassign | `TRANSFORM.DEV.FACT_RCA_MF_DEBT_H3_R8_MONTHLY` · `MEDIAN_DSCR` | Same as row 1. |
| 3 | P0 | `dscr` | *(re-register existing)* `rca_mf_transactions_county_monthly_median_dscr` | Reassign | `TRANSFORM.DEV.FACT_RCA_MF_TRANSACTIONS_COUNTY_MONTHLY` · `MEDIAN_DSCR` | Same. |
| 4 | P0 | `dscr` | *(re-register existing)* `rca_mf_transactions_h3_r8_monthly_median_dscr` | Reassign | `TRANSFORM.DEV.FACT_RCA_MF_TRANSACTIONS_H3_R8_MONTHLY` · `MEDIAN_DSCR` | Same. |
| 5 | P0 | `income` | *(re-register existing)* `acs_demographics_county_median_hhi` | Reassign | `TRANSFORM.DEV.FACT_ACS_DEMOGRAPHICS_COUNTY` · `MEDIAN_HHI` | Rows currently tagged `pipeline`; should be `income` (and siblings for ACS change columns if product wants them under `income`). |
| 6 | P0 | `income` | *(re-register existing)* `census_acs5_h3_r8_snapshot_median_hhi_wavg` | Reassign | `TRANSFORM.DEV.FACT_CENSUS_ACS5_H3_R8_SNAPSHOT` · `MEDIAN_HHI_WAVG` | Same mis-assignment pattern. |
| 7 | P0 | `education` | *(re-register existing)* `markerr_amenity_h3_r8_snapshot_elementary_score_avg` (and related school columns) | Reassign | `TRANSFORM.DEV.FACT_MARKERR_AMENITY_H3_R8_SNAPSHOT` · `ELEMENTARY_SCORE_*`, `MIDDLE_SCORE_*`, `HIGH_SCORE_*` | Many Markerr school-adjacent columns sit on `pipeline`; move to `education` where definition matches. |
| 8 | P0 | TBD | `first_street_climate_risk_*` family | Reassign or **new concept** | `TRANSFORM.DEV.FACT_FIRST_STREET_CLIMATE_RISK_COUNTY` (and snapshot variants) | Today split across `automation` and `rent` for internal observe rows — **not** task automation. Options: add `climate` (or `hazard`) to `concept.csv` + migrate MET, or map to wishlist until IC adopts. |
| 9 | P1 | `dscr` | `property_dscr_monthly_observe` | New `MET_*` | `TRANSFORM.DEV.FACT_PROGRESS_*` / `FACT_BH_*` / loan tape facts (pick canonical column) | No `dscr` concept rows today beyond RCA reassign; property ops DSCR needs explicit `snowflake_column` + grain. |
| 10 | P1 | `permits` | *(concept spine)* — | `CONCEPT_*` | **New model:** `models/transform/dev/concept/concept_permits_market_monthly.sql` joining **`MET_001`** `bps_permits_measure_value` on `TRANSFORM.DEV.FACT_BPS_PERMITS_COUNTY` + `FACT_RCA_MF_CONSTRUCTION_*` already tagged `permits` | Unifies BPS + RCA construction signals; add `schema.yml` tests per playbook. |
| 11 | P1 | `pipeline` / **`supply_pipeline`** | *(mart spine)* — | Concept mart | **`concept_supply_pipeline_market_monthly.sql`** — Realtor CBSA + Zillow new-construction CBSA today; **extend** with `FACT_MARKERR_RENT_LISTINGS_COUNTY_MONTHLY`, `FACT_CHERRE_VACANT_*`, RCA UC when available | Catalog still has many `pipeline` `MET_*` rows on non-supply tables — prefer **`supply_pipeline`** on this mart (``concept.csv`` **CON_011**). |
| 12 | P1 | `automation` | *(mart spine)* — | Concept mart | **`concept_workforce_task_automation_annual.sql`** (county + CBSA + national rollups from **`FACT_COUNTY_AI_REPLACEMENT_RISK`**); **`MET_125`** / **`MET_126`** register deployment + raw susceptibility | Extend with **`FACT_DOL_ONET_*`** SOC slots when product wants national O*NET rows in the same mart. After row 8, exclude mis-assigned First Street columns from any automation union. |
| 13 | P1 | `vacancy` | *(mart spine)* — | Concept mart | **New model:** `concept_vacancy_market_monthly.sql` from `TRANSFORM.DEV.FACT_CHERRE_VACANT_COUNTY_SNAPSHOT` / `FACT_CHERRE_VACANT_H3_R8_SNAPSHOT` + ACS/HUD long-form where `concept_code` supports vacancy | Complement to `concept_occupancy_market_monthly`; many `vacancy` MET rows exist but no unified mart. |
| 14 | P1 | `income` | *(mart spine)* — | Concept mart | **New model:** `concept_income_market_annual.sql` after rows 5–6 | Binds ACS / Oxford / Stanford county income columns already registered under `income` or post-reassign. |
| 15 | P1 | `population` | *(mart spine)* — | Concept mart | **New model:** `concept_population_market_annual.sql` from `FACT_ACS_DEMOGRAPHICS_COUNTY`, `FACT_NBER_CPS_COUNTY`, etc. | Many MET rows; no `concept_population_*` in mart today. |
| 16 | P1 | `crime` | *(mart spine)* — | Concept mart | **New model:** `concept_crime_market_annual.sql` from `FACT_MARKERR_CRIME_H3_R8_SNAPSHOT` + FBI paths if present | Thin promotion today; mart adds slot policy. |
| 17 | P1 | `education` | *(mart spine)* — | Concept mart | **New model:** `concept_school_quality_market_annual.sql` from `FACT_MARKERR_SCHOOLS_COUNTY_SNAPSHOT`, `FACT_STANFORD_SEDA_*` | Post row 7 reassign. |
| 18 | P1 | `rates` | `fred_policy_rate_daily_observe` (example slug) | New `MET_*` | `TRANSFORM.DEV.FACT_RATES_MACRO_NATIONAL_DAILY` · *(column TBD)* | `rates` has 11 active MET but **0** `active` promotion; lock primary policy-rate column(s) and document. |
| 19 | P1 | `inflation` | `macro_cpi_*_daily_observe` (example slug) | New `MET_*` | Same table or split `TRANSFORM.DEV.FACT_INFLATION_*` if exists | Today `inflation` MET share `FACT_RATES_MACRO_NATIONAL_DAILY`; split inflation vs rates for clarity if table is wide. |
| 20 | P1 | `labor` | `bls_laus_participation_rate_county_monthly` | New `MET_*` or **derived** | **Derived (preferred):** `LABOR_FORCE / (LABOR_FORCE + NOT_IN_LABOR_FORCE)` from `TRANSFORM.DEV.FACT_BLS_LAUS_COUNTY_MONTHLY` if columns exist; else new wide column on fact | Only **2** active `labor` MET today; LAUS county file already feeds `employment` / `unemployment`. |
| 21 | P2 | `rent` | `rent_growth_yoy_cbsa_monthly` | `metric_derived` | **New `MDV_*`:** inputs from `MDV_001` / `rent_market_monthly_spine` + lag(12) on same spine or upstream `MET_*` medians | SERVING §1; optional `metric_derived_input` rows. |
| 22 | P2 | `rent` | `rent_cagr_3y_cbsa` / `rent_cagr_5y_cbsa` | `metric_derived` | Same spine as row 21 | SERVING §1. |
| 23 | P2 | `rent` / `income` | `rent_to_income_ratio_cbsa_annual` | `metric_derived` | Inputs: **canonical median rent** (`MET_*` or concept export) + **canonical median HH income** (post row 5–6) | SERVING §1 / §9; blocked until income spine stable. |
| 24 | P2 | `rent` | `rent_median_psf_zip_monthly` | New `MET_*` (activate) | **`MET_052`** → replace `TRANSFORM.DEV.TBD_RENT_PSF_ZIP_MONTHLY` with real fact FQN when built; interim: `TRANSFORM.ZONDA.BTR_H3_R8` · `RENT_PSF_WAVG` / `TRANSFORM.DEV.FACT_ZONDA_BTR_COUNTY_MONTHLY` · `COUNTY_RENT_PSF_WAVG` already registered | Wire **`MDV_005`** + `MDI_006` when `MET_052` is active. |
| 25 | P2 | `absorption` | `tightness_score_cbsa_monthly` | `metric_derived` | **`MDV_006`** + `MDI_007`–`MDI_009` (DOM, listings, HUD CBSA control) | Activate when IC approves composite; SERVING §12. |
| 26 | P2 | `rent` | `arbitrage_score_lower_cbsa_monthly` | `metric_derived` | **`MDV_007`** + `MDI_010`–`MDI_011` | SERVING §14; depends on CoStar / Markerr inputs. |
| 27 | P2 | `absorption` | `net_absorption_units_cbsa_monthly` | New `MET_*` | `TRANSFORM.DEV.FACT_*` *(CoStar / Cherre / Zonda — pick first delivered FACT)* | SERVING §4; no single slug in catalog map today. |
| 28 | P2 | `pipeline` | `uc_units_cbsa_monthly` | New `MET_*` | RCA / CoStar pipeline facts when CBSA-monthly contract exists | SERVING §4–5. |
| 29 | P2 | `pipeline` | `inventory_months_supply_cbsa_monthly` | `metric_derived` | `pipeline_units / trailing_absorption` MET inputs | SERVING §4. |
| 30 | P2 | `permits` | `permit_to_stock_ratio_county_annual` | `metric_derived` | `MET_001` (BPS) ÷ housing stock `MET_*` from HUD/ACS | SERVING §5. |
| 31 | P2 | `transactions` | `transaction_sale_count_cbsa_monthly` | New `MET_*` | `TRANSFORM.DEV.FACT_CHERRE_RECORDER_*` / `FACT_ZONDA_*` / MLS when standardized | Broaden beyond `FACT_ZILLOW_SALES` already in `concept_transactions_market_monthly`. |
| 32 | P2 | `concession` | `concession_weeks_free_property_monthly` | New `MET_*` | `TRANSFORM.DEV.FACT_SFDC_CONCESSION_C` · *(column TBD)* | SERVING §1 / §8; 6 `concession` MET exist but weeks-free not explicit. |
| 33 | P2 | `occupancy` | `opex_escalation_proxy_property_annual` | New `MET_*` or **derived** | Yardi ledger / CAM rules (`FACT_ENTITY_YARDI_CAMRULE`, etc.) — **only if** IC defines the scalar | SERVING §8; heavy `pipeline` entity tables — isolate one underwriting-facing series. |
| 34 | P3 | *(many)* | *(n/a)* | Promotion | All `MET_*` with `data_status_code = under_review` and validated contracts | **~2k+** rows; batch by vendor (`markerr`, `census`, `internal`, …) after P0–P2 shrink mis-assignment noise. |

---

## Concept mart coverage (snapshot)

**Present today (`models/transform/dev/concept/`):** `rent` (market + property), `occupancy`, `unemployment`, `avm`, `absorption`, `migration`, `homeprice`, `transactions`, `delinquency`, `employment`, `valuation`.

**Progress / Fund opco (`models/transform/dev/fund_opco/`):** `disposition` — `concept_disposition_property_varies` (wide `FACT_SFDC_DISPOSITION_C` + `concept_code` envelope; enable with `transform_dev_enable_source_entity_progress_facts`); pair with `concept_progress_disposition_bpo` for BPO triangulation.

**Disposition pricing API alignment (adds still useful):** land **Cherre IHPM** + **county AVM** as `MET_*`/`FACT_*` if not only EDW views; register **Parcl** index + comp pulls if surfaced in Snowflake (else API-only); add **`metric_derived`** rows for list-band / consensus AVM if logic should live in catalog not only Node; optional **`concept_disposition_market_monthly`** only if you need CBSA market context joined to disposition spine (usually join existing `concept_listings_*` / `concept_home_price_*` on ZIP/CBSA).

**Data-only checklist (Fund IV comps / pricing):** [`FUND4_COMPS_PRICING_DATA_UNDERPINNING.md`](./FUND4_COMPS_PRICING_DATA_UNDERPINNING.md) + `scripts/sql/validation/fund4_pricing_api_data_presence.sql` (Snowflake rowcounts / EDW blocks optional).

**Missing vs ranked rows above (mart inventory updated 2026-04-20):** `crime`, `education`, optional `rates` / `inflation` national marts, deeper `noi` / `ltv` / `cap_rate` market rolls if desired. **Shipped in-repo:** `permits`, `vacancy`, `income`, `population`, `labor`, **`concept_workforce_task_automation_annual`** (`automation`), **`concept_supply_pipeline_market_monthly`** (`supply_pipeline` — Realtor + Zillow NC v1).

---

## Changelog

| Version | Notes |
|---------|--------|
| **0.1** | Initial ranked backlog from `concept.csv`, `metric.csv` (current size), concept mart inventory, and SERVING gap themes. |
| **0.2** | Align backlog vocabulary to **single-token** `concept_code` values (`homeprice`, `pipeline`, `education`, `automation`, `spine`, `underwriting`). |
| **0.3** | Add **`disposition`** ontology + `concept_disposition_property_varies`; re-tag `FACT_SFDC_DISPOSITION_C` `MET_*` rows to `disposition` + **property** grain. |
| **0.4** | **`concept_workforce_task_automation_annual`** shipped; **`MET_125`** / **`MET_126`**; P0 reassign RCA DSCR + ACS median HHI internal rows (`pipeline` → **`dscr`** / **`income`**). |
| **0.5** | **`concept_supply_pipeline_market_monthly`** — Realtor CBSA + Zillow new-construction CBSA (extend Markerr / Cherre / RCA later). |
