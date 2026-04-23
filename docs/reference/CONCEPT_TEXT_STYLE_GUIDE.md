# Concept Text Style Guide (Canonical Contract)

Use this contract for all future concept dictionary rows so text is stable for humans, LLM retrieval, and governance review.

**Canonical seed in this repo:** `seeds/reference/catalog/concept_explanation.csv` → **`REFERENCE.CATALOG.CONCEPT_EXPLANATION`**. Keep prose aligned with [`concepts_by_domain.csv`](./concepts_by_domain.csv) and [`../rules/CONCEPT_DOMAIN_POLICY.md`](../rules/CONCEPT_DOMAIN_POLICY.md).

---

## Required fields

- `description`: short one-line summary.
- `definition`: LLM-readable semantic definition.
- `explanation`: 1.5-paragraph applied interpretation for downstream consumers.

---

## Sentence contract

### 1) `description` (exactly 1 sentence)

Purpose: fast label for tables and UI tooltips.

Authoring pattern:

1. `<concept_code> measures <semantic object> for <decision context>.`

Rules:

- 8-18 words.
- No formulas.
- No caveats or exception handling.
- No vendor names.

---

### 2) `definition` (exactly 4 sentences)

Purpose: stable semantic meaning and non-overlap boundaries.

Sentence-by-sentence:

1. **Identity sentence** — what the concept is.
2. **Scope sentence** — unit of analysis and typical grain/time usage.
3. **Boundary sentence** — what it is not (to enforce non-overlap).
4. **Comparability sentence** — which variants must remain separate at `metric_code` level.

Rules:

- Plain language, ontology-first.
- Avoid implementation details.
- Must include at least one explicit non-overlap phrase (e.g., "It does not include ...").

---

### 3) `explanation` (exactly 6 sentences in 1.5 paragraphs)

Purpose: applied meaning for modelers, IC, and product surfaces.

Paragraph 1 (4 sentences):

1. **Economic role** in the causal chain (driver/constraint/outcome).
2. **Decision relevance** for screening/UW/portfolio workflows.
3. **Operationalization** (raw vs derived, high-level).
4. **Interpretation rule** (how to read high/low values).

Paragraph 2 (2 sentences):

5. **Governance risk** (vintage drift, denominator mismatch, lag, definition drift).
6. **Usage requirement** (where to consume it and required metadata).

Rules:

- Insert one blank line between sentence 4 and sentence 5 to create the 1.5-paragraph structure.
- Include at least one governance keyword: `as_of`, `version`, `vintage`, or `metric_id`.
- Keep each sentence atomic and declarative.

---

## CSV schema

Use this header for the concept explanation artifact:

```csv
domain_code,concept_code,description,definition,explanation
```

---

## QA checklist (must pass before publish)

1. Every active `concept_code` in `concepts_by_domain.csv` has exactly one text row.
2. `description` has exactly one sentence.
3. `definition` has exactly four sentences.
4. `explanation` has exactly six sentences with a blank line after sentence four.
5. No workflow/bundle terms are introduced as active concept semantics.
6. Any cross-domain references are expressed as dependencies, not redefinitions.
