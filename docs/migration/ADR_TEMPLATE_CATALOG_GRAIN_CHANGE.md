# ADR template — catalog or grain change (`metric` / `metric_derived` / `CONCEPT_*`)

**Copy this file** to `ADR_YYYYMMDD_short_title.md` (or your team’s ADR folder) and fill sections **Context** through **Consequences**.

---

## Title

[Short title — e.g. “Split rent_market CBSA vs corridor_h3 grain”]

## Status

Proposed | Accepted | Superseded by [link]

## Context

- What economic or product definition changed?
- Which **`concept_code`** / **`metric_derived_code`** / physical models are affected?

## Decision

- **New codes:** list new `metric_id` / `metric_derived_code` / `concept` rows  
- **Deprecation:** old codes marked `is_active = false` or `data_status_code = deprecated` (per seed vocabulary)  
- **Rollback:** single PR reverting CSV + dbt model + tests (see playbook §D)

## Consequences

- Downstream consumers (Presley, BI, scorecard) notified via …  
- **`MIGRATION_LOG.md`** short row + **`MIGRATION_BATCH_INDEX.md`** detail

## Approvals

- Alex (catalog) — required  
- [ ] Consuming team sign-off if breaking

---

*Keep ADRs short; link long evidence to `MIGRATION_BATCH_INDEX.md`.*
