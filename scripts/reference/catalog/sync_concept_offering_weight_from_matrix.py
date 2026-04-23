#!/usr/bin/env python3
"""Emit seeds/reference/catalog/concept_offering_weight.csv from offering_concept_weight_matrix.yml.

Fills a **dense** offering × **concept** matrix (one row per **active offering** × **every concept_code**
in ``concept.csv``, weight **0** where not listed in YAML) so Presley can query routing weights without
sparse NULL semantics and **inactive** concepts (e.g. legacy aliases) still participate in FK-complete
bridges. Explicit rows in ``weights:`` override defaults.
"""
from __future__ import annotations

import csv
import sys
from pathlib import Path

try:
    import yaml  # type: ignore
except ImportError as e:  # pragma: no cover
    print("Install PyYAML: pip install pyyaml", file=sys.stderr)
    raise SystemExit(1) from e


def _all_concept_codes(concept_csv: Path) -> list[str]:
    """Every ``concept_code`` in the vocabulary (including inactive rows)."""
    rows: list[str] = []
    with concept_csv.open(newline="") as f:
        for r in csv.DictReader(f):
            rows.append(str(r["concept_code"]).strip())
    return sorted(set(rows))


def _active_offering_codes(offering_csv: Path) -> list[str]:
    codes: list[str] = []
    with offering_csv.open(newline="") as f:
        for r in csv.DictReader(f):
            if str(r.get("data_status_code", "")).strip().lower() != "active":
                continue
            if str(r.get("is_active", "")).strip().upper() != "TRUE":
                continue
            codes.append(str(r["offering_code"]).strip())
    return sorted(set(codes))


def main() -> None:
    root = Path(__file__).resolve().parents[3]
    cat = root / "seeds" / "reference" / "catalog"
    yml = cat / "offering_concept_weight_matrix.yml"
    out = cat / "concept_offering_weight.csv"
    concept_csv = cat / "concept.csv"
    offering_csv = cat / "offering.csv"

    data = yaml.safe_load(yml.read_text())
    overrides = data.get("weights") or []

    override_map: dict[tuple[str, str], dict] = {}
    for r in overrides:
        key = (str(r["offering_code"]).strip(), str(r["concept_code"]).strip())
        override_map[key] = r

    concepts = _all_concept_codes(concept_csv)
    offerings = _active_offering_codes(offering_csv)

    rows_out: list[dict[str, str | int]] = []
    for oc in offerings:
        primary_set = False
        for cc in concepts:
            key = (oc, cc)
            if key in override_map:
                r = override_map[key]
                w = int(r["weight"])
                is_p = bool(r.get("is_primary"))
                if is_p:
                    primary_set = True
            else:
                w = 0
                is_p = False
            rows_out.append(
                {
                    "concept_code": cc,
                    "offering_code": oc,
                    "weight": w,
                    "is_primary": "TRUE" if is_p else "FALSE",
                }
            )
        # At most one primary per offering: if YAML marks multiple, keep highest weight.
        primaries = [i for i, row in enumerate(rows_out) if row["offering_code"] == oc and row["is_primary"] == "TRUE"]
        if len(primaries) > 1:
            keep = max(primaries, key=lambda i: (rows_out[i]["weight"], rows_out[i]["concept_code"]))
            for i in primaries:
                rows_out[i]["is_primary"] = "TRUE" if i == keep else "FALSE"
        elif not primary_set:
            idxs = [i for i, row in enumerate(rows_out) if row["offering_code"] == oc]
            if idxs:
                best_i = max(idxs, key=lambda i: (rows_out[i]["weight"], -i))
                if rows_out[best_i]["weight"] > 0:
                    rows_out[best_i]["is_primary"] = "TRUE"

    fieldnames = ["concept_code", "offering_code", "weight", "is_primary"]
    with out.open("w", newline="") as f:
        w = csv.DictWriter(f, fieldnames=fieldnames)
        w.writeheader()
        for row in rows_out:
            w.writerow(row)
    print(f"Wrote {len(rows_out)} rows ({len(offerings)} offerings × {len(concepts)} concepts) to {out}")


if __name__ == "__main__":
    main()
