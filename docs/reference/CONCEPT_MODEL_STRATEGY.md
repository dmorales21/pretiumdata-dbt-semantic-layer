# Concept Model Strategy (Draft Mirror)

This repo mirrors concept-strategy guidance in `REFERENCE.DRAFT` for prototyping surfaces, while
`REFERENCE.CATALOG` remains the canonical promoted registry.

## Scope

- A concept is a governed semantic theme that can support comparable `metric_code` registrations.
- Workflow namespaces, bundles, and product panels are not canonical concepts.
- `REFERENCE.DRAFT` can carry provisional mappings and text while owner approval gates promotion.

## Draft assets in this repo

- `seeds/reference/catalog/concept_explanation.csv` (**REFERENCE.CATALOG.CONCEPT_EXPLANATION**)
- `seeds/reference/draft/schema_draft.yml` (tests and draft constraints)

## Machine-connectable key contract

- Use canonical `concept_id` from `concept.csv` (format like `CON_023`) as the primary join key.
- Keep `domain_code` and `concept_code` in the draft row so joins are deterministic and human-readable.

## Promotion rule

- Draft content is for DEV/DEMO prototyping.
- Promotion to `REFERENCE.CATALOG` requires explicit owner approval plus concept non-overlap review.

## Upstream source

This mirror is based on analytics-engine reference strategy docs and adapted to this repo's
catalog contracts (`concept.csv`, `concept_definition_package.csv`, and architecture rules).
