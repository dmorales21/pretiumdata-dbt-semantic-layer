#!/usr/bin/env python3
"""
Legacy: metric-shard-only intake (docs/vendor/metrics/*_metrics.csv).

**Prefer:** `python3 scripts/docs/generate_all_vendors_intake_full.py` — walks the
full `vendor.csv`, uses pretium-ai-dbt merged `metric.csv`, embeds full
`docs/vendor/{code}/{code}.md`, and fills all catalog vendors.

This script remains for ad-hoc shard-only experiments.

Run from semantic-layer repo root:
  python3 scripts/generate_vendor_intake_from_ai_dbt.py

Skips: zillow (hand-curated), semantic_rent_avm_pricing (multi-vendor slice).
Maps shard vendor_code greenstreet_gs -> catalog folder green_street.
"""

from __future__ import annotations

import csv
import hashlib
import re
from collections import Counter, defaultdict
from pathlib import Path

# Semantic repo root = parent of scripts/
SEMANTIC = Path(__file__).resolve().parents[1]
# pretium-ai-dbt is sibling of outer pretiumdata-dbt-semantic-layer folder (dev layout)
_outer = SEMANTIC.parent.parent
AI_DBT = _outer / "pretium-ai-dbt"
if not (AI_DBT / "docs" / "vendor" / "metrics").is_dir():
    AI_DBT = Path("/Users/aposes/dev/pretium/pretium-ai-dbt")

METRICS_DIR = AI_DBT / "docs" / "vendor" / "metrics"
VENDOR_MD_DIR = AI_DBT / "docs" / "vendor"
CONCEPTS_BY_DOMAIN = SEMANTIC / "docs" / "reference" / "concepts_by_domain.csv"
VENDOR_SEED = AI_DBT / "dbt" / "seeds" / "reference" / "catalog" / "vendor.csv"
OUT_ROOT = SEMANTIC / "docs" / "vendors"

SKIP_FILES = {"zillow_metrics.csv", "semantic_rent_avm_pricing_metrics.csv"}

# Shard vendor_code -> reference.catalog.vendor_code (folder name)
SHARD_TO_CATALOG_VENDOR = {
    "greenstreet_gs": "green_street",
}


def load_concept_domain() -> dict[str, str]:
    out: dict[str, str] = {}
    with CONCEPTS_BY_DOMAIN.open() as f:
        r = csv.DictReader(f)
        for row in r:
            out[row["concept_code"].strip()] = row["domain_code"].strip()
    return out


CONCEPT_ALIASES = {
    "home_price": "homeprice",
}


def concept_to_domain(concept: str, concept_domain: dict[str, str]) -> str:
    c = (concept or "").strip()
    if not c:
        return "housing"
    canon = CONCEPT_ALIASES.get(c, c)
    d = concept_domain.get(canon)
    if d:
        return d
    # Heuristics for codes not in semantic enum
    if c in ("rates",):
        return "capital"
    if c in ("pipeline",) and canon not in concept_domain:
        return "place"
    return "housing"


def load_vendor_catalog() -> dict[str, dict]:
    by_code: dict[str, dict] = {}
    with VENDOR_SEED.open() as f:
        for row in csv.DictReader(f):
            by_code[row["vendor_code"]] = row
    return by_code


def man_id(vendor_upper: str, table: str, col: str) -> str:
    h = hashlib.sha256(f"{table}|{col}".encode()).hexdigest()[:8].upper()
    return f"{vendor_upper}_MAN_{h}"


def slug_table(t: str) -> str:
    s = t.replace("TRANSFORM.DEV.", "").replace("TRANSFORM_PROD.FACT.", "")
    s = s.replace("TRANSFORM.", "").lower()
    return re.sub(r"[^a-z0-9]+", "_", s).strip("_")


def pick_mode(counter: Counter) -> str:
    if not counter:
        return "unknown"
    return counter.most_common(1)[0][0]


def read_shard(path: Path) -> list[dict]:
    with path.open(newline="") as f:
        return list(csv.DictReader(f))


def aggregate_physical_rows(rows: list[dict], vendor_code: str) -> list[dict]:
    """One output row per (table_path, snowflake_column)."""
    groups: dict[tuple[str, str], list[dict]] = defaultdict(list)
    for row in rows:
        tp = (row.get("table_path") or "").strip()
        sc = (row.get("snowflake_column") or "").strip()
        if not tp or not sc:
            continue
        groups[(tp, sc)].append(row)

    out_rows: list[dict] = []
    vupper = vendor_code.upper().replace(" ", "_")[:12]
    if vupper == "GREEN_STREET":
        vupper = "GREENSTREET"

    for (tp, sc), grp in sorted(groups.items()):
        ids = [r["metric_id"] for r in grp if r.get("metric_id")]
        codes = [r["metric_code"] for r in grp if r.get("metric_code")]
        labels = [r["metric_label"] for r in grp if r.get("metric_label")]
        concepts = Counter(r.get("concept_code") or "" for r in grp)
        geos = Counter(r.get("geo_level_code") or "" for r in grp)
        freqs = Counter(r.get("frequency_code") or "" for r in grp)
        units = Counter(r.get("unit") or "" for r in grp)
        dirs = Counter(r.get("direction") or "" for r in grp)
        is_active = "TRUE" if any((r.get("is_active") or "").upper() == "TRUE" for r in grp) else "FALSE"
        concept = pick_mode(concepts)
        n_child = len(grp)
        # Prefer stable catalog id when exactly one metric maps to this physical column
        if len(set(ids)) == 1:
            metric_id = ids[0]
            metric_code = codes[0] if len(set(codes)) == 1 else slug_table(tp) + "__" + sc.lower()
            metric_label = labels[0] if labels else f"{sc} — {tp.split('.')[-1]}"
        else:
            metric_id = man_id(vupper, tp, sc)
            metric_code = f"{vendor_code}__{slug_table(tp)}__{sc.lower()}"
            metric_label = f"{sc} — {tp.split('.')[-1]} ({n_child} catalog metrics)"

        out_rows.append(
            {
                "metric_id": metric_id,
                "metric_code": metric_code,
                "metric_label": metric_label,
                "concept_code": concept,
                "geo_level_code": pick_mode(geos),
                "frequency_code": pick_mode(freqs),
                "unit": pick_mode(units) if pick_mode(units) != "unknown" else "varies",
                "direction": pick_mode(dirs) if pick_mode(dirs) != "unknown" else "neutral",
                "is_active": is_active,
                "snowflake_column": sc,
                "table_path": tp,
                "notes_suffix": (
                    f"Collapsed {n_child} catalog rows from pretium-ai-dbt shard. "
                    if n_child > 1
                    else ""
                ),
            }
        )
    return out_rows


def write_metrics_csv(
    path: Path,
    phys_rows: list[dict],
    vendor_code: str,
    concept_domain: dict[str, str],
) -> None:
    header = [
        "metric_id",
        "metric_code",
        "metric_label",
        "concept_code",
        "domain",
        "geo_level_code",
        "frequency_code",
        "unit",
        "direction",
        "is_active",
        "data_status_code",
        "snowflake_column",
        "table_path",
        "coverage_pct",
        "first_vintage",
        "notes",
    ]
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w", newline="") as f:
        w = csv.writer(f)
        w.writerow(header)
        for r in phys_rows:
            domain = concept_to_domain(r["concept_code"], concept_domain)
            notes = (
                r["notes_suffix"]
                + "IS_DERIVED=FALSE unless overridden in pretium-ai-dbt shard. "
                + "coverage_pct/first_vintage sentinels until profiling."
            )
            w.writerow(
                [
                    r["metric_id"],
                    r["metric_code"],
                    r["metric_label"],
                    r["concept_code"],
                    domain,
                    r["geo_level_code"],
                    r["frequency_code"],
                    r["unit"],
                    r["direction"],
                    r["is_active"],
                    "vendor_stated",
                    r["snowflake_column"],
                    r["table_path"],
                    "0",
                    "1900-01-01",
                    notes,
                ]
            )


def find_vendor_md(shard_vendor: str) -> Path | None:
    candidates = [
        VENDOR_MD_DIR / f"{shard_vendor}.md",
        VENDOR_MD_DIR / "cybersyn" / "cybersyn.md",
    ]
    catalog = SHARD_TO_CATALOG_VENDOR.get(shard_vendor, shard_vendor)
    candidates.insert(1, VENDOR_MD_DIR / f"{catalog}.md")
    for p in candidates:
        if p.is_file():
            return p
    return None


def write_guidance(
    path: Path,
    *,
    catalog_vendor: str,
    shard_vendor: str,
    vendor_row: dict | None,
    phys_rows: list[dict],
    md_excerpt: str | None,
    dev_tables: list[str],
) -> None:
    label = (vendor_row or {}).get("vendor_label", catalog_vendor.replace("_", " ").title())
    source_schema = (vendor_row or {}).get("source_schema", "[UNKNOWN — see pretium-ai-dbt vendor seed]")
    refresh = (vendor_row or {}).get("refresh_cadence", "[UNKNOWN]")
    contract = (vendor_row or {}).get("contract_status", "[UNKNOWN]")
    data_share = (vendor_row or {}).get("data_share_type", "[UNKNOWN]")

    md = f"""# {label} — Data Guidance

⚠️ **INTERNAL — contains contract and commercial details**

_Auto-generated from pretium-ai-dbt metric shard (`{shard_vendor}`) and `vendor.csv`. Reconcile with `docs/vendor/{catalog_vendor}/` in this repo if present._

## 1. Overview

{(vendor_row or {}).get("definition", "See pretium-ai-dbt `dbt/seeds/reference/catalog/vendor.csv` and per-vendor methodology in pretium-ai-dbt `docs/vendor/`.")}

**Shard vendor_code:** `{shard_vendor}`  
**Reference catalog vendor_code:** `{catalog_vendor}`

## 2. Contract & Access

| Field | Value |
|-------|-------|
| **contract_status** | {contract} |
| **refresh_cadence** | {refresh} |
| **source_schema (seed)** | `{source_schema}` |
| **data_share_type (seed)** | {data_share} |

**[UNKNOWN — needs profiling]** Exact expiry, redistribution, and Snowflake share object names unless stated in pretium-ai-dbt `sources.yml`.

## 3. Datasets

### `{catalog_vendor}` (physical columns in `vendor_metrics.csv`)

- **Grain:** Varies by `table_path`; dominant `geo_level_code` / `frequency_code` are per-row in the CSV (collapsed from catalog when one column hosts many metrics).
- **Coverage / vintage:** `[UNKNOWN — needs profiling]`; CSV uses sentinel `coverage_pct=0`, `first_vintage=1900-01-01`, `data_status_code=vendor_stated`.
- **DEV tables in this extract:** {len(dev_tables)} of `{len(phys_rows)}` unique physical columns point at `TRANSFORM.DEV` or non-PROD paths.

**Distinct table paths (from shard):**

{chr(10).join("- `" + t + "`" for t in sorted(set(r["table_path"] for r in phys_rows)))}

## 4. Concept Mapping

| metric_id (representative) | concept_code | domain (semantic enum) | direction |
|----------------------------|--------------|-------------------------|-----------|
"""
    for r in phys_rows[:40]:
        dom = concept_to_domain(r["concept_code"], load_concept_domain())
        md += f"| {r['metric_id']} | {r['concept_code']} | {dom} | {r['direction']} |\n"
    if len(phys_rows) > 40:
        md += f"\n*({len(phys_rows) - 40} additional rows in `vendor_metrics.csv`.)*\n"

    md += """
## 5. Join Keys

**[UNKNOWN — needs profiling]** See pretium-ai-dbt `models/sources.yml` and geography bridge models for this vendor. Align ZIP vs ZCTA and CBSA definitions before production joins (`docs/governance/DATASET_POSTAL_VS_ZCTA_INVENTORY.md` in pretium-ai-dbt where applicable).

## 6. Refresh Cadence

Seed / methodology: see **refresh_cadence** above. **Detection:** `[UNKNOWN — needs profiling]`.

## 7. Known Limitations

- Physical-column rows collapse multiple catalog metrics when they share the same `snowflake_column` on a long-form or wide table; use pretium-ai-dbt merged `metric` seed for full `metric_id` list.
- `concept_code` values from pretium-ai-dbt may use underscores (e.g. `home_price`) while this repo’s `concepts_by_domain.csv` uses `homeprice` — normalize before strict semantic validation.

## 8. Changelog

| Date | Commit | Changed Rows | Notes |
|------|--------|--------------|-------|
| 2026-04-23 | `[auto]` | — | Batch intake script `scripts/generate_vendor_intake_from_ai_dbt.py`. |

## Appendix — pretium-ai-dbt methodology excerpt

"""
    if md_excerpt:
        md += md_excerpt[:8000]
    else:
        md += "_No `docs/vendor/{vendor}.md` found in pretium-ai-dbt for this vendor; see shard definitions and `vendor.csv`._\n"

    path.write_text(md, encoding="utf-8")


def main() -> None:
    concept_domain = load_concept_domain()
    catalog = load_vendor_catalog()

    for csv_path in sorted(METRICS_DIR.glob("*_metrics.csv")):
        if csv_path.name in SKIP_FILES:
            continue
        rows = read_shard(csv_path)
        if not rows:
            continue
        shard_vendor = (rows[0].get("vendor_code") or "").strip()
        if not shard_vendor:
            continue
        catalog_vendor = SHARD_TO_CATALOG_VENDOR.get(shard_vendor, shard_vendor)
        out_dir = OUT_ROOT / catalog_vendor
        phys = aggregate_physical_rows(rows, shard_vendor)
        if not phys:
            continue
        write_metrics_csv(out_dir / "vendor_metrics.csv", phys, shard_vendor, concept_domain)

        md_path = find_vendor_md(shard_vendor)
        excerpt = None
        if md_path:
            excerpt = md_path.read_text(encoding="utf-8")

        vendor_row = catalog.get(catalog_vendor) or catalog.get(shard_vendor)
        dev_tables = [r["table_path"] for r in phys if "TRANSFORM.DEV" in r["table_path"] or "DEV." in r["table_path"]]

        write_guidance(
            out_dir / "vendor_guidance.md",
            catalog_vendor=catalog_vendor,
            shard_vendor=shard_vendor,
            vendor_row=vendor_row,
            phys_rows=phys,
            md_excerpt=excerpt,
            dev_tables=dev_tables,
        )
        print(f"Wrote {out_dir.relative_to(SEMANTIC)}/ (rows={len(phys)})")


if __name__ == "__main__":
    main()
