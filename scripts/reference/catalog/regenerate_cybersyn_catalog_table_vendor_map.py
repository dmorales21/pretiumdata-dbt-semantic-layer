#!/usr/bin/env python3
"""Regenerate seeds/reference/catalog/cybersyn_catalog_table_vendor_map.csv from the TSV name list.

Source list (one table_name per line, no header):
  docs/migration/artifacts/cybersyn_global_government_catalog_table_names.tsv

Run from repo root:
  python3 scripts/reference/catalog/regenerate_cybersyn_catalog_table_vendor_map.py

Rules are ordered: first matching prefix wins. Update RULES when CYBERSYN_DATA_CATALOG
gains new domains or when agency attribution changes (see CYBERSYN_GLOBAL_GOVERNMENT_BRING_IN_MATRIX.md).
"""
from __future__ import annotations

import csv
from pathlib import Path

# This file lives at scripts/reference/catalog/<name>.py → repo root is three levels up.
REPO = Path(__file__).resolve().parents[3]
TSV = REPO / "docs/migration/artifacts/cybersyn_global_government_catalog_table_names.tsv"
OUT = REPO / "seeds/reference/catalog/cybersyn_catalog_table_vendor_map.csv"

# (prefix, underlying_vendor_code, matrix_tier, domain_family_key) — first match wins.
RULES: list[tuple[str, str, int, str]] = [
    ("geography_", "census", 1, "geography"),
    ("american_community_survey_", "acs", 2, "american_community_survey"),
    ("housing_urban_development_", "hud", 2, "housing_urban_development"),
    ("us_real_estate_", "zillow", 2, "us_real_estate"),
    ("usps_address_change_", "usps", 2, "usps_address_change"),
    ("irs_origin_destination_migration_", "irs", 2, "irs_origin_destination_migration"),
    ("irs_migration_by_characteristic_", "irs", 2, "irs_migration_by_characteristic"),
    ("irs_individual_income_", "irs", 2, "irs_individual_income"),
    ("irs_form990_investments_", "irs", 2, "irs_form990"),
    ("irs_form990_loans_and_notes_", "irs", 2, "irs_form990"),
    ("irs_form990_", "irs", 2, "irs_form990"),
    ("bureau_of_labor_statistics_employment_", "bls", 2, "bureau_of_labor_statistics_employment"),
    ("bureau_of_labor_statistics_price_", "bls", 2, "bureau_of_labor_statistics_price"),
    ("fhfa_house_price_", "fhfa", 3, "fhfa_house_price"),
    ("fhfa_mortgage_performance_", "fhfa", 3, "fhfa_mortgage_performance"),
    ("fhfa_uniform_appraisal_", "fhfa", 3, "fhfa_uniform_appraisal"),
    ("freddie_mac_housing_", "freddie_mac", 3, "freddie_mac_housing"),
    ("home_mortgage_disclosure_", "cfpb", 3, "home_mortgage_disclosure"),
    ("fdic_branch_locations_", "fdic", 4, "fdic_branch_locations"),
    ("fdic_summary_of_deposits_", "fdic", 4, "fdic_summary_of_deposits"),
    ("financial_institution_", "internal", 4, "financial_institution"),
    ("financial_branch_entities_", "internal", 4, "financial_branch_entities"),
    ("financial_cfpb_complaint_", "cfpb", 4, "financial_cfpb_complaint"),
    ("financial_economic_indicators_", "fred", 4, "financial_economic_indicators"),
    ("fbi_crime_", "fbi", 5, "fbi_crime"),
    ("urban_crime_incident_log_", "internal", 5, "urban_crime_incident_log"),
    ("urban_crime_", "internal", 5, "urban_crime"),
    ("nws_weather_", "nws", 5, "nws_weather"),
    ("noaa_", "nws", 5, "noaa"),
    ("fema_", "fema", 5, "fema"),
    ("point_of_interest_addresses_", "internal", 6, "point_of_interest_addresses"),
    ("point_of_interest_", "internal", 6, "point_of_interest"),
    ("us_addresses_", "usps", 6, "us_addresses"),
    ("public_data_", "cybersyn", 1, "public_data"),
    ("calendar_", "cybersyn", 1, "calendar"),
    ("naics_code", "census", 88, "naics_code"),
]


def classify(table_name: str) -> tuple[str, int, str]:
    t = table_name.lower()
    for prefix, vendor, tier, fam in RULES:
        if t.startswith(prefix.lower()):
            return vendor, tier, fam
    return "cybersyn", 99, "other_cybersyn_share"


def main() -> None:
    names = [ln.strip() for ln in TSV.read_text().splitlines() if ln.strip()]
    rows: list[dict[str, str]] = []
    for n in sorted(set(names)):
        v, tier, fam = classify(n)
        rows.append(
            {
                "table_name": n,
                "domain_family_key": fam,
                "underlying_vendor_code": v,
                "matrix_tier": str(tier),
                "is_pit_companion": "true" if n.endswith("_pit") else "false",
            }
        )
    OUT.parent.mkdir(parents=True, exist_ok=True)
    with OUT.open("w", newline="") as f:
        w = csv.DictWriter(
            f,
            fieldnames=[
                "table_name",
                "domain_family_key",
                "underlying_vendor_code",
                "matrix_tier",
                "is_pit_companion",
            ],
        )
        w.writeheader()
        w.writerows(rows)
    print(f"Wrote {len(rows)} rows to {OUT.relative_to(REPO)}")


if __name__ == "__main__":
    main()
