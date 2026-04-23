#!/usr/bin/env bash
# Regenerate models/serving/iceberg/SERVING_ICEBERG_LANDING_ZONE_SPEC.md from Snowflake.
# Requires: snowsql on PATH, profile defaulting to connection "pretium".
#
# Usage (from repo root):
#   ./scripts/serving/run_generate_serving_iceberg_landing_zone_spec.sh
#   ./scripts/serving/run_generate_serving_iceberg_landing_zone_spec.sh -- --full-schema --output docs/serving/SERVING_ICEBERG_LANDING_ZONE_SPEC.md
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
export PRETIUMDATA_DBT_SEMANTIC_LAYER_ROOT="${PRETIUMDATA_DBT_SEMANTIC_LAYER_ROOT:-${ROOT}}"
if [[ "${1:-}" == "--" ]]; then
  shift
fi
exec python3 "${ROOT}/scripts/serving/generate_serving_iceberg_landing_zone_spec.py" "$@"
