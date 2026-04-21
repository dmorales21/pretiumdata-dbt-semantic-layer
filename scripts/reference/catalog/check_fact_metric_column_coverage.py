#!/usr/bin/env python3
"""
Validate column-level metric registration coverage for semantic-layer fact models.

Definition used:
  A metric is a measurable column on a FACT model, registered in
  seeds/reference/catalog/metric.csv by (table_path, snowflake_column).

Usage:
  python3 scripts/reference/catalog/check_fact_metric_column_coverage.py
"""
from __future__ import annotations

import csv
from pathlib import Path
from typing import Dict, List, Set, Tuple

import yaml


REPO = Path(__file__).resolve().parents[3]
MODELS_ROOT = REPO / "models" / "transform" / "dev"
METRIC_CSV = REPO / "seeds" / "reference" / "catalog" / "metric.csv"

# Non-metric helpers/grain fields commonly present on fact models.
NON_METRIC_COLUMNS = {
    "date_reference",
    "date",
    "as_of_date",
    "as_of_month",
    "as_of_week",
    "geo_id",
    "id_county",
    "id_cbsa",
    "id_zip",
    "id_state",
    "state_fips",
    "county_fips",
    "cbsa_id",
    "zip",
    "zcta",
    "tract",
    "block_group",
    "h3_r8",
    "h3_r9",
    "h3_r10",
    "vendor_code",
    "metric_id",
    "metric_code",
    "unit",
    "frequency",
    "frequency_code",
    "geo_level_code",
    "is_active",
    "created_at",
    "updated_at",
    "_loaded_at",
    "_ingested_at",
    "dbt_updated_at",
    "geo_name",
    "variable",
    "vintage_year",
    "data_year",
    "naics_2digit",
    "naics_title",
    "year",
    "quarter",
    "return_group",
    "income_bracket",
    "age_group",
    "risk_tier",
    "census_place_fips",
    "has_census_geo",
    "census_geo_source",
    "geo_id_residence_block_group",
    "geo_id_workplace_block_group",
    "building_use",
    "estimate_type",
    "measure",
    "cbsa_code_omb",
}

MEASURE_HINTS = (
    "value",
    "rate",
    "index",
    "score",
    "count",
    "price",
    "rent",
    "wage",
    "employment",
    "unemployment",
    "income",
    "permit",
    "migration",
    "vacancy",
    "occupancy",
    "cap_rate",
    "ltv",
    "delinquency",
    "exposure",
    "risk",
    "yield",
    "units",
)


def _load_metric_index() -> Dict[str, Set[str]]:
    idx: Dict[str, Set[str]] = {}
    with METRIC_CSV.open(newline="", encoding="utf-8-sig") as f:
        for row in csv.DictReader(f):
            table_path = (row.get("table_path") or "").strip().upper()
            col = (row.get("snowflake_column") or "").strip().upper()
            if not table_path or not col:
                continue
            idx.setdefault(table_path, set()).add(col)
    return idx


def _iter_schema_files() -> List[Path]:
    return sorted(MODELS_ROOT.rglob("schema*.yml"))


def _is_fact_model(name: str) -> bool:
    return name.startswith("fact_")


def _column_is_metric_candidate(col: str) -> bool:
    c = col.strip().lower()
    if not c or c in NON_METRIC_COLUMNS:
        return False
    if c.endswith("_id") or c.endswith("_code"):
        return False
    return any(h in c for h in MEASURE_HINTS)


def _table_path_for_model(model_name: str) -> str:
    # transform/dev FACT models materialize to TRANSFORM.DEV.<OBJECT>
    return f"TRANSFORM.DEV.{model_name.upper()}"


def main() -> int:
    metric_idx = _load_metric_index()
    facts_checked = 0
    total_candidates = 0
    total_missing = 0
    missing_rows: List[Tuple[str, str]] = []

    for schema_path in _iter_schema_files():
        doc = yaml.safe_load(schema_path.read_text(encoding="utf-8")) or {}
        models = doc.get("models") or []
        for model in models:
            name = (model or {}).get("name") or ""
            if not _is_fact_model(name):
                continue

            facts_checked += 1
            table_path = _table_path_for_model(name)
            registered_cols = metric_idx.get(table_path, set())

            for col_def in (model.get("columns") or []):
                col_name = (col_def or {}).get("name") or ""
                if not _column_is_metric_candidate(col_name):
                    continue
                total_candidates += 1
                if col_name.upper() not in registered_cols:
                    total_missing += 1
                    missing_rows.append((table_path, col_name.upper()))

    print(f"fact_models_checked={facts_checked}")
    print(f"metric_candidate_columns={total_candidates}")
    print(f"missing_metric_rows={total_missing}")
    if missing_rows:
        print("missing_examples:")
        for tp, col in missing_rows[:200]:
            print(f"  - table_path={tp} snowflake_column={col}")

    return 1 if total_missing else 0


if __name__ == "__main__":
    raise SystemExit(main())
