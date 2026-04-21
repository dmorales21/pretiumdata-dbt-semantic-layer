#!/usr/bin/env python3
"""
Regenerate docs/vendor/** from seeds/reference/catalog/vendor.csv.

Creates:
  docs/vendor/0_inventory/vendors_inventory.csv
  docs/vendor/0_inventory/vendors_inventory.yaml
  docs/vendor/{vendor_code}/{vendor_code}.md
  docs/vendor/{vendor_code}/dictionary.csv
  docs/vendor/{vendor_code}/dictionary.yaml

Run from repo root (pretiumdata-dbt-semantic-layer/pretiumdata-dbt-semantic-layer):
  python3 scripts/docs/generate_vendor_context_from_seed.py
"""
from __future__ import annotations

import csv
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parents[2]
CSV_PATH = REPO / "seeds" / "reference" / "catalog" / "vendor.csv"
DOCS_VENDOR = REPO / "docs" / "vendor"
INV_DIR = DOCS_VENDOR / "0_inventory"

# Optional primary migration / vet doc (relative to docs/)
MIGRATION_DOC_BY_VENDOR: dict[str, str] = {
    "zillow": "migration/MIGRATION_TASKS_ZILLOW_TRANSFORM_DEV.md",
    "redfin": "migration/MIGRATION_TASKS_STANFORD_REDFIN.md",
    "cherre": "migration/MIGRATION_TASKS_CHERRE.md",
    "costar": "migration/MIGRATION_TASKS_COSTAR.md",
    "cybersyn": "migration/MIGRATION_TASKS_CYBERSYN_SOURCE_SNOW.md",
    "apartmentiq": "migration/MIGRATION_TASKS_APARTMENTIQ_YARDI_MATRIX.md",
    "yardi": "migration/MIGRATION_TASKS_YARDI_BH_PROGRESS.md",
    "first_street": "migration/MIGRATION_TASKS_FIRST_STREET_RCA.md",
    "oxford_economics": "migration/MIGRATION_TASKS_OXFORD_SOURCE_ENTITY_DEV.md",
    "acs": "migration/MIGRATION_TASKS_TRANSFORM_BPS_CENSUS_BLS_LODES.md",
    "bls": "migration/MIGRATION_TASKS_TRANSFORM_BPS_CENSUS_BLS_LODES.md",
    "census": "migration/MIGRATION_TASKS_TRANSFORM_BPS_CENSUS_BLS_LODES.md",
    "lehd": "migration/MIGRATION_TASKS_TRANSFORM_BPS_CENSUS_BLS_LODES.md",
    "cps_nber": "migration/MIGRATION_TASKS_TRANSFORM_BPS_CENSUS_BLS_LODES.md",
    "fbi": "migration/VENDOR_CATALOG_ONLY_SNOWSQL_VET.md",
    "fdic": "migration/VENDOR_CATALOG_ONLY_SNOWSQL_VET.md",
    "usps": "migration/VENDOR_CATALOG_ONLY_SNOWSQL_VET.md",
    "nws": "migration/VENDOR_CATALOG_ONLY_SNOWSQL_VET.md",
    "cfpb": "migration/VENDOR_CATALOG_ONLY_SNOWSQL_VET.md",
}


def yaml_escape(s: str) -> str:
    return '"' + s.replace("\\", "\\\\").replace('"', '\\"') + '"'


def write_vendor_yaml(path: Path, row: dict[str, str]) -> None:
    lines = [
        "# AUTO-GENERATED — edit dictionary.csv for field-level detail; refresh via generate_vendor_context_from_seed.py",
        f"vendor_id: {row['vendor_id']}",
        f"vendor_code: {row['vendor_code']}",
        f"vendor_label: {yaml_escape(row['vendor_label'])}",
        f"source_schema: {yaml_escape(row.get('source_schema', '') or '')}",
        f"data_type: {row.get('data_type', '')}",
        f"refresh_cadence: {row.get('refresh_cadence', '')}",
        f"contract_status: {row.get('contract_status', '')}",
        f"data_share_type: {row.get('data_share_type', '')}",
        f"is_active: {str(row.get('is_active', '')).lower() in ('true', '1', 'yes')}",
        "dictionary_version: '0.1'",
        "fields: []  # populate from Snowflake DESCRIBE + product dictionaries",
    ]
    if row.get("vertical_codes", "").strip():
        lines.append(f"vertical_codes: {yaml_escape(row['vertical_codes'].strip())}")
    path.write_text("\n".join(lines) + "\n", encoding="utf-8")


def write_vendor_md(path: Path, row: dict[str, str], mig: str) -> None:
    code = row["vendor_code"]
    mig_section = ""
    if mig:
        mig_section = f"\nPrimary task / vet doc: [`{mig}`](../{mig})\n"
    else:
        mig_section = (
            "\nNo vendor-specific migration file is mapped in `generate_vendor_context_from_seed.py` yet. Use "
            "[`migration/VENDOR_CONCEPT_COVERAGE_MATRIX.md`](../migration/VENDOR_CONCEPT_COVERAGE_MATRIX.md) "
            "and [`migration/MIGRATION_REGISTRY_VENDORS_DATASETS_METRICS.md`](../migration/MIGRATION_REGISTRY_VENDORS_DATASETS_METRICS.md).\n"
        )

    body = f"""# Vendor: {row["vendor_label"]} (`{code}`)

**Catalog row:** `vendor_id` = `{row["vendor_id"]}` in `seeds/reference/catalog/vendor.csv`.

## 1. Identity

{row.get("definition", "").strip()}

## 2. Contract (catalog)

| Attribute | Value |
|-----------|-------|
| **data_type** | {row.get("data_type", "")} |
| **refresh_cadence** | {row.get("refresh_cadence", "")} |
| **contract_status** | {row.get("contract_status", "")} |
| **source_schema** | `{row.get("source_schema", "")}` |
| **is_active** | {row.get("is_active", "")} |
| **data_share_type** | {row.get("data_share_type", "")} |
| **is_motherduck_served** | {row.get("is_motherduck_served", "")} |
| **vertical_codes** | {row.get("vertical_codes", "") or "—"} |

## 3. Read path (methodology)

1. Prefer **Jon silver** on **TRANSFORM** (vendor schema, e.g. `TRANSFORM.ZILLOW`, `TRANSFORM.MARKERR`) or **`TRANSFORM.FACT`** when the object exists and is vetted (see [MIGRATION_RULES.md](../migration/MIGRATION_RULES.md)).
2. Otherwise use the catalog **`source_schema`** (`RAW.*`, `SOURCE_ENTITY.*`, `SOURCE_SNOW.*`, etc.) and declare reads in `models/sources/*.yml`.
3. **Alex dbt** implements **`TRANSFORM.DEV`** read-throughs and typed facts under `models/transform/dev/` where applicable.
4. **REFERENCE.CATALOG** (`metric`, `dataset`, `bridge_product_type_metric`) must align with real column names after `DESCRIBE` / lineage — see [METRIC_INTAKE_CHECKLIST.md](../migration/METRIC_INTAKE_CHECKLIST.md).

## 4. Grain and concepts

See [VENDOR_CONCEPT_COVERAGE_MATRIX.md](../migration/VENDOR_CONCEPT_COVERAGE_MATRIX.md) for **`{code}`** × concept × dataset gaps and stretch mappings.

## 5. Field dictionary (machine-readable)

| File | Description |
|------|-------------|
| `dictionary.csv` | Column/metric-level rows (extend per inventory). |
| `dictionary.yaml` | Vendor-level metadata + empty `fields` list until filled. |

## 6. Migration and QA
{mig_section}
## 7. Related rules

- [OPERATING_MODEL.md](../OPERATING_MODEL.md)
- [rules/TRANSFORM_VENDOR_DESIGN_PRINCIPLES.md](../rules/TRANSFORM_VENDOR_DESIGN_PRINCIPLES.md)
"""
    path.write_text(body, encoding="utf-8")


def write_dictionary_csv(path: Path, row: dict[str, str]) -> None:
    """Bootstrap CSV with one placeholder row; extend with DESCRIBE / data dictionary work."""
    fieldnames = [
        "logical_name",
        "physical_name",
        "object_kind",
        "data_type",
        "grain",
        "unit",
        "description",
        "source_object",
        "notes",
    ]
    with path.open("w", newline="", encoding="utf-8") as f:
        w = csv.DictWriter(f, fieldnames=fieldnames)
        w.writeheader()
        w.writerow(
            {
                "logical_name": "_placeholder",
                "physical_name": "",
                "object_kind": "pending_inventory",
                "data_type": "",
                "grain": "",
                "unit": "",
                "description": "Replace with real fields/metrics as vendor objects are inventoried in Snowflake.",
                "source_object": row.get("source_schema", ""),
                "notes": f"vendor_code={row['vendor_code']}",
            }
        )


def main() -> int:
    if not CSV_PATH.is_file():
        print(f"Missing vendor seed: {CSV_PATH}", file=sys.stderr)
        return 1

    rows: list[dict[str, str]] = []
    with CSV_PATH.open(newline="", encoding="utf-8") as f:
        for row in csv.DictReader(f):
            rows.append(row)

    INV_DIR.mkdir(parents=True, exist_ok=True)

    inv_csv = INV_DIR / "vendors_inventory.csv"
    extra_fields = ["docs_subpath", "primary_migration_doc"]
    with inv_csv.open("w", newline="", encoding="utf-8") as f:
        base_keys = list(rows[0].keys()) if rows else []
        fieldnames = base_keys + extra_fields
        w = csv.DictWriter(f, fieldnames=fieldnames)
        w.writeheader()
        for row in rows:
            code = row["vendor_code"]
            mig = MIGRATION_DOC_BY_VENDOR.get(code, "")
            out_row = dict(row)
            out_row["docs_subpath"] = f"docs/vendor/{code}/"
            out_row["primary_migration_doc"] = mig
            w.writerow(out_row)

    inv_yaml = INV_DIR / "vendors_inventory.yaml"
    yl = [
        "# AUTO-GENERATED from seeds/reference/catalog/vendor.csv",
        'version: "1.0"',
        f"source_file: {yaml_escape(str(CSV_PATH.relative_to(REPO)))}",
        "vendors:",
    ]
    for row in rows:
        code = row["vendor_code"]
        mig = MIGRATION_DOC_BY_VENDOR.get(code, "")
        yl.append("  - vendor_id: " + row["vendor_id"])
        yl.append("    vendor_code: " + code)
        yl.append("    vendor_label: " + yaml_escape(row["vendor_label"]))
        yl.append("    docs_subpath: " + yaml_escape(f"docs/vendor/{code}/"))
        yl.append("    primary_migration_doc: " + (yaml_escape(mig) if mig else "null"))
        yl.append("    source_schema: " + yaml_escape(row.get("source_schema", "") or ""))
        yl.append("    data_type: " + yaml_escape(row.get("data_type", "") or ""))
        yl.append("    contract_status: " + yaml_escape(row.get("contract_status", "") or ""))
    inv_yaml.write_text("\n".join(yl) + "\n", encoding="utf-8")

    for row in rows:
        code = row["vendor_code"]
        vdir = DOCS_VENDOR / code
        vdir.mkdir(parents=True, exist_ok=True)
        mig = MIGRATION_DOC_BY_VENDOR.get(code, "")
        write_vendor_md(vdir / f"{code}.md", row, mig)
        write_dictionary_csv(vdir / "dictionary.csv", row)
        write_vendor_yaml(vdir / "dictionary.yaml", row)

    print(f"Wrote {len(rows)} vendors under {DOCS_VENDOR}")
    print(f"Inventory: {inv_csv} , {inv_yaml}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
