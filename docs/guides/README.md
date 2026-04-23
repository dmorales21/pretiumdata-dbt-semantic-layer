# Guides — short operational references

One-page references that sit beside (not replace) **`docs/rules/`** and **`docs/migration/`**.

| Guide | Purpose |
|-------|---------|
| [DATA_LAYER_QUESTIONS_BY_PIPELINE_STAGE.md](./DATA_LAYER_QUESTIONS_BY_PIPELINE_STAGE.md) | Which **question** each stage answers, Pretium anchors, **layer gate**, and a **per-layer dbt test checklist** (aligned to analytics-engine §8 for ideas). |

**CI helpers (not Markdown guides):** [`dbt_layer_gate_raw_transform_before_facts.sh`](../../scripts/ci/dbt_layer_gate_raw_transform_before_facts.sh) (source tests only) · [`dbt_enforce_layer_gate_then_bls_laus_stack.sh`](../../scripts/ci/dbt_enforce_layer_gate_then_bls_laus_stack.sh) (gate → **`dbt build`** LAUS FACT + unemployment concept, including their data tests).
