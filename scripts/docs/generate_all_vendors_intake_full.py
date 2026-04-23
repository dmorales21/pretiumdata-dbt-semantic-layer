#!/usr/bin/env python3
"""
Populate docs/vendors/{vendor_code}/ for every vendor in seeds/reference/catalog/vendor.csv.

- vendor_metrics.csv: unique (table_path, snowflake_column) from **this repo’s**
  seeds/reference/catalog/metric.csv when present; else pretium-ai-dbt merged metric.csv;
  else dictionary.csv non-placeholder rows; else a single TBD placeholder row aligned to source_schema.
- vendor_guidance.md: INTERNAL header + catalog table + full embed of docs/vendor/{code}/{code}.md
  when present, else seed-based stub. Includes migration link from 0_inventory when available.

Preserves hand-authored docs/vendors/zillow/ (skip zillow).

Run from repo root (pretiumdata-dbt-semantic-layer/pretiumdata-dbt-semantic-layer):
  python3 scripts/docs/generate_all_vendors_intake_full.py
"""

from __future__ import annotations

import csv
import hashlib
import re
import sys
from collections import Counter, defaultdict
from pathlib import Path

REPO = Path(__file__).resolve().parents[2]
SEMANTIC_VENDOR = REPO / "seeds" / "reference" / "catalog" / "vendor.csv"
CONCEPTS_BY_DOMAIN = REPO / "docs" / "reference" / "concepts_by_domain.csv"
DOCS_VENDOR = REPO / "docs" / "vendor"
INV_CSV = DOCS_VENDOR / "0_inventory" / "vendors_inventory.csv"
OUT_ROOT = REPO / "docs" / "vendors"

# Prefer semantic-layer catalog (single-repo runs); else pretium-ai-dbt merged metric.csv.
_SEMANTIC_METRIC = REPO / "seeds" / "reference" / "catalog" / "metric.csv"
_AI_DBT = REPO.parent.parent / "pretium-ai-dbt"
_METRIC_AI = _AI_DBT / "dbt" / "seeds" / "reference" / "catalog" / "metric.csv"
_METRIC_FALLBACK = Path("/Users/aposes/dev/pretium/pretium-ai-dbt/dbt/seeds/reference/catalog/metric.csv")


def resolve_metric_csv() -> Path | None:
    if _SEMANTIC_METRIC.is_file():
        return _SEMANTIC_METRIC
    if _METRIC_AI.is_file():
        return _METRIC_AI
    if _METRIC_FALLBACK.is_file():
        return _METRIC_FALLBACK
    return None


METRIC_CSV = resolve_metric_csv()
METRIC_CSV_LABEL = (
    "semantic-layer seeds/reference/catalog/metric.csv"
    if METRIC_CSV and METRIC_CSV.resolve() == _SEMANTIC_METRIC.resolve()
    else "pretium-ai-dbt metric.csv"
    if METRIC_CSV
    else "none"
)

# catalog vendor_code -> pretium-ai-dbt metric.csv vendor_code values
CATALOG_TO_METRIC_VENDORS: dict[str, list[str]] = {
    "green_street": ["greenstreet_gs"],
}

CONCEPT_ALIASES = {"home_price": "homeprice"}
SKIP_VENDORS = frozenset({"zillow"})


def load_concept_domain() -> dict[str, str]:
    out: dict[str, str] = {}
    with CONCEPTS_BY_DOMAIN.open(encoding="utf-8") as f:
        for row in csv.DictReader(f):
            out[row["concept_code"].strip()] = row["domain_code"].strip()
    return out


def concept_to_domain(concept: str, concept_domain: dict[str, str]) -> str:
    c = (concept or "").strip()
    if not c:
        return "housing"
    canon = CONCEPT_ALIASES.get(c, c)
    if canon in concept_domain:
        return concept_domain[canon]
    if c == "rates":
        return "capital"
    return "housing"


def metric_vendor_keys(catalog_vendor: str) -> list[str]:
    return CATALOG_TO_METRIC_VENDORS.get(catalog_vendor, [catalog_vendor])


def load_pretium_metrics_by_vendor() -> dict[str, list[dict]]:
    by: dict[str, list[dict]] = defaultdict(list)
    if METRIC_CSV is None or not METRIC_CSV.is_file():
        return by
    with METRIC_CSV.open(newline="", encoding="utf-8") as f:
        for row in csv.DictReader(f):
            vc = (row.get("vendor_code") or "").strip()
            if vc:
                by[vc].append(row)
    return by


def load_inventory_migration() -> dict[str, str]:
    out: dict[str, str] = {}
    if not INV_CSV.is_file():
        return out
    with INV_CSV.open(encoding="utf-8") as f:
        for row in csv.DictReader(f):
            p = (row.get("primary_migration_doc") or "").strip()
            if p:
                out[row["vendor_code"]] = p
    return out


def man_id(prefix: str, table: str, col: str) -> str:
    h = hashlib.sha256(f"{table}|{col}".encode()).hexdigest()[:8].upper()
    p = re.sub(r"[^A-Z0-9]", "_", prefix.upper())[:12]
    return f"{p}_MAN_{h}"


def slug_table(t: str) -> str:
    s = t.replace("TRANSFORM.DEV.", "").replace("TRANSFORM_PROD.FACT.", "")
    s = s.replace("TRANSFORM.", "").lower()
    return re.sub(r"[^a-z0-9]+", "_", s).strip("_")


def pick_mode(counter: Counter) -> str:
    if not counter:
        return "unknown"
    return counter.most_common(1)[0][0]


def aggregate_physical_rows(rows: list[dict], catalog_vendor: str) -> list[dict]:
    groups: dict[tuple[str, str], list[dict]] = defaultdict(list)
    for row in rows:
        tp = (row.get("table_path") or "").strip()
        sc = (row.get("snowflake_column") or "").strip()
        if not tp or not sc:
            continue
        groups[(tp, sc)].append(row)

    prefix = catalog_vendor
    out_rows: list[dict] = []
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
        if len(set(ids)) == 1:
            metric_id = ids[0]
            metric_code = codes[0] if len(set(codes)) == 1 else f"{catalog_vendor}__{slug_table(tp)}__{sc.lower()}"
            metric_label = labels[0] if labels else f"{sc} — {tp.split('.')[-1]}"
        else:
            metric_id = man_id(prefix, tp, sc)
            metric_code = f"{catalog_vendor}__{slug_table(tp)}__{sc.lower()}"
            metric_label = f"{sc} — {tp.split('.')[-1]} ({n_child} pretium catalog metrics)"

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
                    f"Collapsed {n_child} catalog `metric.csv` rows onto this physical column ({METRIC_CSV_LABEL}). "
                    if n_child > 1
                    else f"Sourced from catalog `metric.csv` ({METRIC_CSV_LABEL}). "
                ),
            }
        )
    return out_rows


def rows_from_dictionary(catalog_vendor: str) -> list[dict]:
    path = DOCS_VENDOR / catalog_vendor / "dictionary.csv"
    if not path.is_file():
        return []
    rows_out: list[dict] = []
    with path.open(newline="", encoding="utf-8") as f:
        for row in csv.DictReader(f):
            logical = (row.get("logical_name") or "").strip()
            phys = (row.get("physical_name") or "").strip()
            if logical == "_placeholder" or not phys:
                continue
            src = (row.get("source_object") or "UNKNOWN").strip()
            rows_out.append(
                {
                    "metric_id": man_id(catalog_vendor, src, phys),
                    "metric_code": f"{catalog_vendor}__{logical or phys}".lower().replace(" ", "_"),
                    "metric_label": (row.get("description") or logical or phys)[:500],
                    "concept_code": "pipeline",
                    "geo_level_code": (row.get("grain") or "unknown").strip() or "unknown",
                    "frequency_code": "varies",
                    "unit": (row.get("unit") or "varies").strip() or "varies",
                    "direction": "neutral",
                    "is_active": "TRUE",
                    "snowflake_column": phys,
                    "table_path": src,
                    "notes_suffix": "From semantic-layer `docs/vendor/{}/dictionary.csv` (non-placeholder). ".format(
                        catalog_vendor
                    ),
                }
            )
    return rows_out


def placeholder_row(catalog_vendor: str, vendor_row: dict) -> list[dict]:
    schema = (vendor_row.get("source_schema") or "UNKNOWN").strip()
    label = (vendor_row.get("vendor_label") or catalog_vendor).strip()
    mid = man_id(catalog_vendor, schema, "TBD")
    return [
        {
            "metric_id": mid,
            "metric_code": f"{catalog_vendor}_pending_physical_inventory",
            "metric_label": f"{label} — physical column inventory pending",
            "concept_code": "pipeline",
            "geo_level_code": "unknown",
            "frequency_code": "varies",
            "unit": "varies",
            "direction": "neutral",
            "is_active": "TRUE",
            "snowflake_column": "TBD",
            "table_path": schema,
            "notes_suffix": (
                "No catalog `metric.csv` rows and no populated `dictionary.csv` fields for this vendor. "
                "Replace after Snowflake `DESCRIBE` + catalog registration. "
            ),
        }
    ]


def write_metrics_csv(path: Path, phys_rows: list[dict], concept_domain: dict[str, str]) -> None:
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
    with path.open("w", newline="", encoding="utf-8") as f:
        w = csv.writer(f)
        w.writerow(header)
        for r in phys_rows:
            domain = concept_to_domain(r["concept_code"], concept_domain)
            notes = (
                r["notes_suffix"]
                + "IS_DERIVED=FALSE unless noted in source catalog. "
                + "coverage_pct=0 and first_vintage=1900-01-01 are profiling sentinels (data_status_code=vendor_stated)."
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


def stub_vendor_md(catalog_vendor: str, row: dict, mig: str) -> str:
    label = row.get("vendor_label", catalog_vendor)
    mig_line = f"Primary migration / vet doc: [`{mig}`](../{mig})\n" if mig else ""
    return f"""# Vendor: {label} (`{catalog_vendor}`)

**Catalog row:** `vendor_id` = `{row.get("vendor_id", "")}` in `seeds/reference/catalog/vendor.csv`.

## 1. Identity

{row.get("definition", "")}

## 2. Contract (catalog)

| Attribute | Value |
|-----------|-------|
| **data_type** | {row.get("data_type", "")} |
| **refresh_cadence** | {row.get("refresh_cadence", "")} |
| **contract_status** | {row.get("contract_status", "")} |
| **source_schema** | `{row.get("source_schema", "")}` |
| **data_share_type** | {row.get("data_share_type", "")} |

## 3. Read path

See [OPERATING_MODEL.md](../OPERATING_MODEL.md) and [migration/MIGRATION_RULES.md](../migration/MIGRATION_RULES.md).

{mig_line}
"""


def write_guidance_full(
    path: Path,
    *,
    catalog_vendor: str,
    vendor_row: dict,
    phys_rows: list[dict],
    raw_metric_count: int,
    embedded_md: str | None,
    mig: str,
) -> None:
    label = vendor_row.get("vendor_label", catalog_vendor)
    dev_n = sum(1 for r in phys_rows if "DEV" in r["table_path"].upper() or ".DEV." in r["table_path"])
    body = embedded_md.strip() if embedded_md else stub_vendor_md(catalog_vendor, vendor_row, mig)

    # Avoid duplicate H1 if embedded file already starts with #
    if body.startswith("#"):
        body = "\n".join(body.splitlines()[1:]).lstrip("\n")

    md = f"""# {label} — Data Guidance

⚠️ **INTERNAL — contract and operational context**

**Intake bundle:** `docs/vendors/{catalog_vendor}/` (machine column inventory + this narrative).  
**Canonical vendor hub:** `docs/vendor/{catalog_vendor}/` (dictionary + structured stubs).

---

## Catalog snapshot (seeds/reference/catalog/vendor.csv)

| Field | Value |
|-------|-------|
| **vendor_id** | `{vendor_row.get("vendor_id", "")}` |
| **vendor_code** | `{catalog_vendor}` |
| **vendor_label** | {vendor_row.get("vendor_label", "")} |
| **definition** | {vendor_row.get("definition", "")} |
| **data_type** | {vendor_row.get("data_type", "")} |
| **refresh_cadence** | {vendor_row.get("refresh_cadence", "")} |
| **contract_status** | {vendor_row.get("contract_status", "")} |
| **source_schema** | `{vendor_row.get("source_schema", "")}` |
| **data_share_type** | {vendor_row.get("data_share_type", "")} |
| **vertical_codes** | {vendor_row.get("vertical_codes", "") or "—"} |

**Primary migration doc (inventory):** {f"[{mig}](../{mig})" if mig else "— (see `docs/vendor/0_inventory/vendors_inventory.csv`)"}

---

## Vendor methodology (full text from `docs/vendor/{catalog_vendor}/{catalog_vendor}.md`)

{body}

---

## Physical metrics summary (`vendor_metrics.csv`)

| Metric | Value |
|--------|-------|
| **Unique physical columns** | {len(phys_rows)} |
| **Rows pointing at TRANSFORM.DEV / DEV paths** | {dev_n} |
| **Raw catalog metrics (metric.csv rows for this vendor)** | {raw_metric_count} |

Long-form facts collapse many catalog `metric_id` values onto one `snowflake_column` (for example `VALUE` / `METRIC_VALUE`); use **`seeds/reference/catalog/metric.csv`** (this repo) or pretium-ai-dbt merged `metric.csv` for the full metric registry.

---

## Concept mapping (physical rows, first 50)

| metric_id | concept_code | domain | direction | table_path | snowflake_column |
|-----------|--------------|--------|-----------|------------|------------------|
"""
    concept_domain = load_concept_domain()
    for r in phys_rows[:50]:
        dom = concept_to_domain(r["concept_code"], concept_domain)
        md += f"| {r['metric_id']} | {r['concept_code']} | {dom} | {r['direction']} | `{r['table_path']}` | `{r['snowflake_column']}` |\n"
    if len(phys_rows) > 50:
        md += f"\n*({len(phys_rows) - 50} additional rows in `vendor_metrics.csv`.)*\n"

    md += f"""

---

## Join keys, refresh detection, limitations

**[UNKNOWN — needs profiling]** unless the embedded methodology above states otherwise. Align postal vs ZCTA, CBSA vintages, and agency attribution (especially Cybersyn-sourced agency tables) before production joins.

---

## Changelog

| Date | Commit | Notes |
|------|--------|-------|
| 2026-04-23 | `[auto]` | Full intake regeneration via `scripts/docs/generate_all_vendors_intake_full.py`. |
"""
    path.write_text(md, encoding="utf-8")


def main() -> int:
    if not SEMANTIC_VENDOR.is_file():
        print("Missing vendor seed", SEMANTIC_VENDOR, file=sys.stderr)
        return 1
    print("metric.csv source:", METRIC_CSV or "(none)", "| label:", METRIC_CSV_LABEL)
    concept_domain = load_concept_domain()
    pretium_by = load_pretium_metrics_by_vendor()
    inv_mig = load_inventory_migration()

    vendors = list(csv.DictReader(SEMANTIC_VENDOR.open(encoding="utf-8")))
    for row in vendors:
        code = row["vendor_code"].strip()
        if code in SKIP_VENDORS:
            print("skip", code)
            continue

        keys = metric_vendor_keys(code)
        pretium_rows: list[dict] = []
        for k in keys:
            pretium_rows.extend(pretium_by.get(k, []))
        raw_n = len(pretium_rows)

        if pretium_rows:
            phys = aggregate_physical_rows(pretium_rows, code)
        else:
            phys = rows_from_dictionary(code)
            if not phys:
                phys = placeholder_row(code, row)

        out_dir = OUT_ROOT / code
        write_metrics_csv(out_dir / "vendor_metrics.csv", phys, concept_domain)

        md_path = DOCS_VENDOR / code / f"{code}.md"
        embedded = md_path.read_text(encoding="utf-8") if md_path.is_file() else None
        mig = inv_mig.get(code, "")
        write_guidance_full(
            out_dir / "vendor_guidance.md",
            catalog_vendor=code,
            vendor_row=row,
            phys_rows=phys,
            raw_metric_count=raw_n,
            embedded_md=embedded,
            mig=mig,
        )
        print(code, "metrics_csv_rows=", len(phys), "pretium_metrics=", raw_n)

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
