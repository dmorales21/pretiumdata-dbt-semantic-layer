#!/usr/bin/env bash
# Enforced order for **TRANSFORM.BLS → FACT → CONCEPT** (PretiumData semantic layer):
#   1) **Layer gate** — `dbt test` on Jon silver `source('bls_transform', …)` (grain + nulls + uniqueness).
#   2) **Build** — `dbt build` on `fact_bls_laus_county`, `fact_bls_laus_cbsa_monthly`,
#      `concept_unemployment_market_monthly` (runs **models + their data tests** in one pass).
#
# Usage (repo root, Snowflake profile/target configured):
#   bash scripts/ci/dbt_enforce_layer_gate_then_bls_laus_stack.sh
#   bash scripts/ci/dbt_enforce_layer_gate_then_bls_laus_stack.sh --target dev
#
# Same sequence is wired into `.github/workflows/semantic_layer_catalog_and_quality.yml` job
# `dbt_seed_test_catalog_snowflake` when Snowflake CI is enabled (after catalog seed + test).
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT"

echo "== (1/2) Layer gate: source tests on TRANSFORM.BLS (before FACT) =="
dbt test "$@" --selector layer_gate_before_fact_bls_laus

echo "== (2/2) Build + data tests: LAUS FACT read-throughs + unemployment concept =="
dbt build "$@" --select fact_bls_laus_county fact_bls_laus_cbsa_monthly concept_unemployment_market_monthly

echo "== BLS LAUS semantic stack enforced OK =="
