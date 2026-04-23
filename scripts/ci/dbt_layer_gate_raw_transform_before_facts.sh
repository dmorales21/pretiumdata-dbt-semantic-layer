#!/usr/bin/env bash
# Layer gate: validate **upstream** landings / Jon **TRANSFORM.[VENDOR]** silver (dbt **sources**) before
# building Alex **TRANSFORM.DEV.FACT_*** read-throughs that depend on them.
#
# Usage (from repo root, Snowflake target configured):
#   bash scripts/ci/dbt_layer_gate_raw_transform_before_facts.sh
#   bash scripts/ci/dbt_layer_gate_raw_transform_before_facts.sh --target dev
#
# First wave: **TRANSFORM.BLS** LAUS tables behind ``fact_bls_laus_*``. Extend the selector + source tags
# as more FACT families adopt the same gate.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT"

echo "== dbt layer gate: source tests (Jon silver before FACT read-throughs) =="
dbt test "$@" --selector layer_gate_before_fact_bls_laus

echo "== layer gate passed =="
