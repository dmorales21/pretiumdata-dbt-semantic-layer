# Dataset Pipeline Status — Controlled Vocabulary
# Column: pipeline_status in REFERENCE.CATALOG.dataset
# Owner: Alex | Updated: 2026-04-18

## Values

| pipeline_status | Definition | canonical_source_schema | Next action |
|---|---|---|---|
| `transform_ready` | TRANSFORM.[VENDOR] exists with data; canonical read path for ANALYTICS models | TRANSFORM.[VENDOR] | None — ready to consume |
| `source_prod_only` | SOURCE_PROD.[VENDOR] is the current readable path; TRANSFORM layer not yet built | SOURCE_PROD.[VENDOR] | Jon to build TRANSFORM.[VENDOR] cleanse layer |
| `source_entity_only` | SOURCE_ENTITY.[OPCO] landed; no TRANSFORM layer yet | SOURCE_ENTITY.[OPCO] | David to build TRANSFORM.[VENDOR]_[OPCO] layer |
| `raw_only` | RAW.[VENDOR] exists; no TRANSFORM or SOURCE_PROD; Alex DEV path only | RAW.[VENDOR] | Jon to build TRANSFORM.[VENDOR] |
| `blocked` | Pipeline broken; 0 rows or data share disconnected; do not read | varies | David / Jon to fix ingestion |
| `skeleton` | Schema registered but no data confirmed in any layer | — | Ingestion not started |

## Rules
# 1. ANALYTICS models may only read from datasets where pipeline_status = transform_ready
# 2. pipeline_status = source_prod_only is Alex DEV-only (TRANSFORM.DEV work)
# 3. pipeline_status = blocked or skeleton → data_status_code must = blocked or under_review
# 4. TRANSFORM.FACT does not exist yet — any dataset whose canonical path
#    is TRANSFORM.FACT gets pipeline_status = source_prod_only until Jon builds it
# 5. This file is the authoritative reference for the column; update on every pipeline promotion
