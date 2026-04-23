# Cybersyn — ad hoc Snowflake SQL

| Script | Purpose |
|--------|---------|
| [vet_us_addresses_cybersyn.sql](./vet_us_addresses_cybersyn.sql) | Row counts, POI relationship duplicate check, `h3_latlng_to_cell` smoke. |
| [build_reference_postalcode_h3_10_support.sql](./build_reference_postalcode_h3_10_support.sql) | Full rebuild: `US_ADDRESSES` → `REFERENCE.GEOGRAPHY.POSTALCODE_*` + H3-10 dominant/confident layers. |
| [build_reference_postalcode_h3_10_qa.sql](./build_reference_postalcode_h3_10_qa.sql) | QA tables: `POSTALCODE_H3_10_DOMINANT_QA`, `POSTALCODE_H3_10_ZIP_PROFILE`, `POSTALCODE_H3_10_INVALID_POSTAL_CODES` (run after support build). |
| [build_reference_postalcode_h3_10_production_smoothed.sql](./build_reference_postalcode_h3_10_production_smoothed.sql) | **`POSTALCODE_H3_10_PRODUCTION_SMOOTHED`** — multi-statement build (avoids Snowflake single-statement compile timeout); component-level smoothing; does not alter `DOMINANT_CONFIDENT`. Requires QA script first. |

**Run:** `snowsql -c pretium -f scripts/sql/cybersyn/<script>.sql`

**Governance:** `REFERENCE.GEOGRAPHY` is primarily the **census spine** in [ARCHITECTURE_RULES.md](../../docs/rules/ARCHITECTURE_RULES.md). These Cybersyn-derived **POSTALCODE_*** tables are a **modeled postal ↔ H3 support** surface, not USPS polygons — confirm with IC before treating as canonical alongside census objects.
