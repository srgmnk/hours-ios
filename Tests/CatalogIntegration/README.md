# Catalog integration tests

Run from the repository root:

```sh
bash Tests/CatalogIntegration/run.sh
```

This runner includes the entire existing `Tests/CitySearch` geographic identity, ordering, row stability, and asynchronous cancellation suite in the same binary, followed by expanded-catalog integration checks. It compiles current production models, local search, identity helpers, conservative deduplication, coordinate lookup, actual marker projection, and night-light selection. MapKit callbacks are controlled fakes; no network or user storage is touched.

The temporary provider copy exposes private access and replaces only its MapKit import. Actual CityStore load/save/migration uses injected in-memory I/O and a FileManager that redirects all application/widget URLs into disposable test directories; shared defaults and widget reloads are isolated. The two identity helpers are also extracted with an injected provider to test synthetic ambiguity. UI row identity and map projection are extracted verbatim. All generated sources, binary resources, module caches, synthetic fixture bundles, and executables remain outside the repository.

Checks cover all 3,000 entries, immutable original 152 records and coordinates, explicit unique identities, current-host Foundation zone acceptance, actual alias normalization, model round trips, all 14 required local queries, same-name city diversity, frozen legacy scope, ambiguous/mismatched location matching, safe missing-zone fallback, remote failures preserving local results, conservative remote/local separation, and exactly 152 original base lights plus legitimate dynamic saved-city lights. Frozen projected Float values detect unintended changes to the original light projection.

Zone acceptance on the current host does not establish spatial time-zone assignment or minimum-supported-iOS compatibility. These tests do not claim rendered UI, frame timing, physical-device, touch, or haptic coverage. The separate simulator performance harness records its own environment and limits.
