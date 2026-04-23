{% macro reference_geo_zip_to_cbsa_and_h3_ctes() %}
{#-
  **ZIP → census spine + dominant H3** — composable ``WITH`` CTE list for ZIP-native vendor facts.

  **Includes** (in order, comma-separated for use after ``WITH``):

  1. ``{{ reference_geo_zip_to_cbsa_ctes() }}`` — HUD postal ZIP → primary county → primary CBSA
     (``zip_enriched``: ``id_zip``, ``county_fips``, ``cbsa_id``).
  2. ``zip_h3_ranked`` / ``h3_zip`` — dominant **H3 R6 / H3 R8** per USPS ZIP from
     ``source('h3_polyfill_bridges','bridge_zip_h3_r8_polyfill')`` (columns ``ZIP_CODE``, ``H3_R6_HEX``,
     ``H3_R8_HEX``, ``WEIGHT``, optional ``CBSA_ID``), joined to ``zip_enriched`` so ``h3_zip.id_cbsa`` prefers
     bridge CBSA when populated, else HUD-primary CBSA.

  **Join pattern:** ``LEFT JOIN zip_enriched AS ze ON <lpad_zip> = ze.id_zip`` and
  ``LEFT JOIN h3_zip AS h ON <lpad_zip> = h.id_zip``.

  **Do not use** on facts whose silver grain is already **county / CBSA / H3 / national** — avoid duplicative
  rollups on the fact; keep those enrichments in ``CONCEPT_*`` unions only when needed.

  **Related:** ``macros/semantic/reference_geo_zip_to_cbsa_ctes.sql``; Markerr ``fact_markerr_rent_*``;
  ``docs/reference/FACT_GEO_REFERENCE_INVENTORY.md``.
-#}
{{ reference_geo_zip_to_cbsa_ctes() }},

zip_h3_ranked AS (
    SELECT
        LPAD(TRIM(TO_VARCHAR(b.ZIP_CODE)), 5, '0') AS id_zip,
        TRIM(TO_VARCHAR(b.H3_R6_HEX)) AS h3_6_hex,
        TRIM(TO_VARCHAR(b.H3_R8_HEX)) AS h3_8_hex,
        NULLIF(TRIM(TO_VARCHAR(b.CBSA_ID)), '') AS bridge_cbsa_raw,
        TRY_TO_DOUBLE(TO_VARCHAR(b.WEIGHT)) AS w,
        ROW_NUMBER() OVER (
            PARTITION BY LPAD(TRIM(TO_VARCHAR(b.ZIP_CODE)), 5, '0')
            ORDER BY TRY_TO_DOUBLE(TO_VARCHAR(b.WEIGHT)) DESC NULLS LAST, TRIM(TO_VARCHAR(b.H3_R8_HEX))
        ) AS rn
    FROM {{ source('h3_polyfill_bridges', 'bridge_zip_h3_r8_polyfill') }} AS b
    WHERE b.ZIP_CODE IS NOT NULL
      AND b.H3_R8_HEX IS NOT NULL
),

h3_zip AS (
    SELECT
        r.id_zip,
        r.h3_6_hex,
        r.h3_8_hex,
        COALESCE(
            CASE
                WHEN r.bridge_cbsa_raw IS NOT NULL AND TRIM(r.bridge_cbsa_raw) <> ''
                    THEN LPAD(TRIM(r.bridge_cbsa_raw), 5, '0')
            END,
            ze.cbsa_id
        ) AS id_cbsa
    FROM zip_h3_ranked AS r
    LEFT JOIN zip_enriched AS ze
        ON r.id_zip = ze.id_zip
    WHERE r.rn = 1
)
{% endmacro %}
