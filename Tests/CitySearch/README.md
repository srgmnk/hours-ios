# City search regression tests

Run from the repository root:

```sh
bash Tests/CitySearch/run.sh
```

The runner compiles the actual current search provider, models, merge helper, and extracted row-identity implementation. A temporary provider copy substitutes controllable MapKit callbacks and exposes private members for adversarial cancellation tests. No production test hooks or additional target membership are required. The real bundled catalog is used. No user storage or network is touched by these tests.

Coverage includes local/remote overlap, repeated remote representations, Moscow across countries, Springfield across US states in the same time zone, Added state, catalog IDs, provider alternate identifiers, ambiguous evidence, ordering, repeated queries, row stability, late callbacks, cancellation during resolution, and cancelled fallback suppression.

## Reviewed catalog anchors

The production table contains only individually inspected MapKit city-level responses. Country codes, coordinates, names, context/address equality, and absence of a POI category gate catalog matching. Coordinates are rounded to six decimals solely to represent the returned anchor; this is not a municipality radius or proximity heuristic.

| Catalog ID | Country code | Latitude | Longitude | Observed |
|---|---|---|---|---|
| bangkok-th | TH | 13.7537858 | 100.4985251 | 2026-10-26 |
| moscow-ru | RU | 55.7586642 | 37.6192919 | 2026-10-26 |
| paris-fr | FR | 48.8567879 | 2.3510768 | 2026-10-26 |

Names and city representations matched the catalog; the full address matched the full city context. These responses had no provider identifier. London was deliberately not anchored: the inspected UK response represented Southwark, London.

Unsupported or changed responses remain separate. Matching legacy name/country/time-zone IDs alone is intentionally insufficient. New geographically supported remote selections receive `city:mapkit:` identities; existing stored records are not rewritten. Older ambiguous noncatalog records cannot be retrospectively located from their stored name/time zone and must not be guessed equivalent. Localization or changed provider metadata may prevent a future exact representation match; these are false-negative risks, not reasons to broaden matching automatically.

Live MapKit and rendered UI checks remain separate from deterministic fake-network tests. Recheck on an iPhone after deployment, especially across locale changes and MapKit data updates.
