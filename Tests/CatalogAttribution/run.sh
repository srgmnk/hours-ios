#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/../.."
repo_root="$PWD"
attribution_work=$(mktemp -d /private/tmp/Hours-CatalogAttribution.XXXXXX)
trap 'rm -rf "$attribution_work"' EXIT
xcrun swiftc -swift-version 5 -default-isolation MainActor -parse-as-library \
  -module-cache-path "$attribution_work/ModuleCache" \
  Hours/Features/Settings/Legal/LegalDocument.swift \
  Hours/Features/Settings/Legal/CityDataAttribution.swift \
  Tests/CatalogAttribution/AttributionTests.swift \
  -o "$attribution_work/tests"
"$attribution_work/tests" "$repo_root" "$attribution_work"
