# City search regression tests

Run from the repository root:

```sh
bash Tests/CitySearch/run.sh
```

The runner compiles the actual current search provider, models, merge helper, and extracted row-identity implementation. A temporary provider copy substitutes controllable MapKit callbacks and exposes private members for adversarial cancellation tests. No production test hooks or additional target membership are required. The real 3,000-row bundled catalog is used. A frozen original 152-row fixture retains the exact short-query baseline assertion. No user storage or network is touched by these tests.

Coverage includes local/remote overlap, repeated remote representations, Moscow across countries, Springfield across US states in the same time zone, Added state, catalog IDs, provider alternate identifiers, ambiguous evidence, ordering, repeated queries, row stability, late callbacks, cancellation during resolution, and cancelled fallback suppression.

## Reviewed catalog anchors

The production table contains only individually inspected MapKit city-level responses. Country codes, coordinates, names/aliases, compatible time zones, context/address equality, and absence of a POI category gate catalog matching. Coordinates use the actual Swift six-decimal formatter solely to represent the returned anchor; this is not a municipality radius or proximity heuristic. In particular, the captured Qingyuan latitude `23.6904885` formats as `23.690488` on the tested runtime, so do not manually round it when updating fixtures. A verified catalog winner retains its exact local identity, presentation and registry coordinates, including when alternate provider IDs join groups.

| Catalog ID | Country code | Latitude | Longitude | Observed |
|---|---|---|---|---|
| bangkok-th | TH | 13.7537858 | 100.4985251 | 2026-10-26 |
| moscow-ru | RU | 55.7586642 | 37.6192919 | 2026-10-26 |
| paris-fr | FR | 48.8567879 | 2.3510768 | 2026-10-26 |
| geonames-499099 (Samara) | RU | 53.2066899 | 50.2353862 | 2026-11-08 |
| geonames-1797945 (Qingyuan) | CN | 23.6904885 | 113.0463228 | 2026-11-08 |
| geonames-2653941 (Cambridge, England) | GB | 52.2021717 | 0.1248301 | 2026-11-08 |
| geonames-4409896 (Springfield, Missouri) | US | 37.2071144 | -93.2923603 | 2026-11-08 |

Names and city representations matched the catalog; the full address matched the full city context. These responses had no provider identifier. London was deliberately not anchored: the inspected UK response represented Southwark, London.

Unsupported or changed responses remain separate. Matching legacy name/country/time-zone IDs alone is intentionally insufficient. Remote selections with sufficient geographic keys receive `city:mapkit:` identities; existing stored records are not rewritten. Older ambiguous noncatalog records cannot be retrospectively located from their stored name/time zone and must not be guessed equivalent. Localization or changed provider metadata may prevent a future exact representation match; these are false-negative risks, not reasons to broaden matching automatically.

Live MapKit and rendered UI checks remain separate from deterministic fake-network tests. Recheck on an iPhone after deployment, especially across locale changes and MapKit data updates.

`bash Tests/CatalogIntegration/run.sh` runs this entire suite plus the expanded catalog, compatibility, coordinate and night-light checks in one compilation.

`bash Tests/CitySearchQuality/run.sh /private/tmp/Hours-CitySearchQuality-run` runs this entire suite plus recorded Samara/Самара, small-town/transliteration, cross-source coordinate preservation and request-count regressions. It rejects matched roads, water features, POIs and administrative substitutions while retaining corroborated settlements. See that runner's README for actual fixture provenance and an optional pre-correction processing benchmark.
