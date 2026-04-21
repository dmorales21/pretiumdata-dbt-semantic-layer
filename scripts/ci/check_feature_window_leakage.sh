#!/usr/bin/env bash
# Slug: **window_leakage_audit** (3) — static scan of `models/analytics/feature/*.sql` for **future-looking** window frames.
# Exit **1** if `UNBOUNDED FOLLOWING` / `… FOLLOWING` appears (review each hit; comments still count).
# Pair with `QA_AS_OF_SNAPSHOT_ENFORCEMENT` and model-level `dbt_utils.expression_is_true` on `month_start`.
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
DIR="${ROOT}/models/analytics/feature"
if ! compgen -G "${DIR}/*.sql" > /dev/null; then
  echo "window_leakage_audit: no SQL files under ${DIR}" >&2
  exit 0
fi
if grep -EIn 'UNBOUNDED FOLLOWING|ROWS BETWEEN[^;]*FOLLOWING|RANGE BETWEEN[^;]*FOLLOWING' "${DIR}"/*.sql; then
  echo "window_leakage_audit: review grep hits above (confirm no future rows leak into rolling FEATURE columns)." >&2
  exit 1
fi
echo "window_leakage_audit: OK — no UNBOUNDED FOLLOWING / FOLLOWING window frames in ${DIR}/*.sql"
