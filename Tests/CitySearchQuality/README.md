# City search quality regression tests

Run the complete existing city-search suite plus the focused quality cases:

```sh
bash Tests/CitySearchQuality/run.sh /private/tmp/Hours-CitySearchQuality-run
```

Choose a fresh artifact directory. The runner snapshots the current production provider, models, geographic deduplicator and coordinate data before compiling an optimized Swift executable. Only access control and the MapKit import change in temporary copies. Controllable callbacks replay recorded MapKit data; the tests make no network requests and do not open user storage. Build products, caches, source snapshots and measurements remain outside the repository.

The recorded fixtures identify their capture environment and source fingerprint. They are evidence of specific MapKit responses; live service results are not claimed to be stable across dates, networks, regions or languages. Adversarial cases intentionally alter recorded country, time zone, geography or feature type and are labeled synthetic in the test source.

Coverage includes one retained local Samara identity with unchanged catalog coordinates, rejected street/water/admin substitutions, geographically distinct same-name settlements, stable local publication prefixes and row IDs, valid absent small-town selections, local ordering and thresholds, rapid Russian-to-English query cancellation, clearing during direct resolution and stale callbacks. The full existing search suite runs in the same binary.

For an optional before/after result-processing benchmark, supply a directory containing the pre-correction `CitySearchProvider.swift` and `CitySearchDeduplicator.swift` snapshots:

```sh
QUALITY_BASELINE_DIR=/private/tmp/Hours-CitySearch-Quality-2026-11-08/baseline \
  bash Tests/CitySearchQuality/run.sh /private/tmp/Hours-CitySearchQuality-comparison
```

The baseline types are renamed only in the external harness and load the same approved 3,000-city catalog. `quality-results.json` records deduplication, validation and local-search timing distributions. These are optimized desktop measurements with fake service callbacks, not physical-iPhone or live-network latency measurements.
