# Frozen original catalog fixtures

`original-cities.json` is the unmodified 152-row catalog captured before the Stage A/Stage B expansion. `original-night-lights.json` contains its sorted catalog keys, canonical identities, and reviewed WGS84 light inputs. These are isolated test fixtures, not a second production catalog.

Snapshot: production commit `0e386d1882fba4b8fc0007e37c998d8cc21bd8aa`, November 8, 2026. The original coordinate provenance includes GeoNames CC BY 4.0, Natural Earth public domain, and the reviewed Dubai/Muscat exceptions described in `Hours/Services/Location/LocalCityCoordinates.swift`. GeoNames attribution: https://www.geonames.org/ — https://creativecommons.org/licenses/by/4.0/.

`original-night-light-positions.json` records the 152 Float-projected positions produced by the independently compiled original Stage A NightCityLights implementation. IDs and numeric Float values are frozen to detect unintentional projection or point changes.
