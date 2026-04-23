#!/usr/bin/env python3
"""Emit docs/migration/CATALOG_METRICS_BY_CONCEPT_INVENTORY.md from catalog seeds."""
from __future__ import annotations

import csv
from collections import Counter, defaultdict
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
CONCEPT = ROOT / "seeds/reference/catalog/concept.csv"
# Built **metric.csv** (REFERENCE slice). For full backlog by concept, point at **metric_raw.csv** instead.
METRIC = ROOT / "seeds/reference/catalog/metric.csv"
OUT = ROOT / "docs/migration/CATALOG_METRICS_BY_CONCEPT_INVENTORY.md"


def is_active(v: str | None) -> bool:
    return str(v).strip().upper() in ("TRUE", "1", "T", "YES")


def main() -> None:
    concepts: dict[str, dict[str, str]] = {}
    with CONCEPT.open(newline="", encoding="utf-8") as f:
        for row in csv.DictReader(f):
            concepts[row["concept_code"]] = row

    rows = list(csv.DictReader(METRIC.open(newline="", encoding="utf-8")))
    active = [r for r in rows if is_active(r.get("is_active"))]

    by: dict[str, list[dict[str, str]]] = defaultdict(list)
    for r in active:
        cc = (r.get("concept_code") or "").strip()
        by[cc].append(r)

    lines: list[str] = [
        "# Catalog inventory — active `MET_*` rows by `concept_code`",
        "",
        "**Generated:** `scripts/ci/print_catalog_metrics_by_concept_inventory.py` from `metric.csv` (active) × `concept.csv`.",
        "",
        "**Naming:** single-token `concept_code` where practical (`homeprice`, `supply_pipeline`, `school_quality`, `listings`, `automation`, `spine`, `underwriting`); `cap_rate` kept as a standard acronym.",
        "",
        "| `concept_code` | Active MET rows | Promoted (`data_status_code=active`) | Distinct `table_path` (count) | Example `table_path` |",
        "|----------------|----------------:|---------------------------------------:|------------------------------:|------------------------|",
    ]

    def promoted(r: dict[str, str]) -> bool:
        return (r.get("data_status_code") or "").strip() == "active"

    for cc in sorted(concepts.keys()):
        xs = by.get(cc, [])
        prom = sum(1 for x in xs if promoted(x))
        tp = Counter((x.get("table_path") or "").strip() for x in xs if x.get("table_path"))
        top = tp.most_common(1)
        top_path = top[0][0][:72] + ("…" if top and len(top[0][0]) > 72 else "") if top else "—"
        lines.append(f"| `{cc}` | {len(xs)} | {prom} | {len(tp)} | `{top_path}` |")

    orphan = sorted(set(by) - set(concepts.keys()) - {""})
    if orphan:
        lines.extend(["", "## Orphan `concept_code` on metrics (not in `concept.csv`)"])
        for o in orphan:
            lines.append(f"- `{o}`: {len(by[o])} active rows")

    lines.extend(
        [
            "",
            "---",
            "",
            "## Changelog",
            "",
            "| Version | Notes |",
            "|---------|--------|",
            "| **0.1** | Initial generator; refresh after bulk `metric.csv` changes. |",
            "",
        ]
    )

    OUT.write_text("\n".join(lines) + "\n", encoding="utf-8")
    print(f"Wrote {OUT.relative_to(ROOT)}")


if __name__ == "__main__":
    main()
