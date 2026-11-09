# City-data attribution checks

Run `bash Tests/CatalogAttribution/run.sh` from the repository root.

These offline checks compile the production legal-route and attribution models. They verify that Privacy/Terms URLs and theme parameters are preserved, attribution has its own native route, source/license notices load under flat and nested bundle layouts, the notice fingerprints the actual catalog, and the complete bundled CC BY 4.0 text matches the pinned upstream license.

The catalog fingerprint check intentionally fails if a future catalog changes without updating its dated provenance notice. No source archives, network requests, app storage or existing tests are required.

The full iOS build separately verifies automatic resource membership and the SwiftUI Settings/sheet integration.
