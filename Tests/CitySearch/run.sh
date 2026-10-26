#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/../.."
work=$(mktemp -d /private/tmp/Hours-CitySearchTests.XXXXXX)
trap 'rm -rf "$work"' EXIT
# Compile the actual provider against controllable MapKit callbacks. Only the import
# and access control change in this temporary copy; production files are untouched.
python3 - "$work" <<'PY'
import pathlib, sys
out = pathlib.Path(sys.argv[1])
s = pathlib.Path('Hours/CitySearchProvider.swift').read_text()
(out / 'Provider.swift').write_text(s.replace('import MapKit\n', '').replace('private ', ''))
s = pathlib.Path('Hours/AddCitySheetView.swift').read_text()
start = s.index('    private struct DisplayResult:')
brace = s.index('{', start)
depth = 1
end = brace + 1
while depth:
    depth += (s[end] == '{') - (s[end] == '}')
    end += 1
(out / 'Rows.swift').write_text('import Foundation\n' + s[start:end].replace('private struct', 'struct', 1))
PY
cp Hours/Resources/cities.json "$work/cities.json"
xcrun swiftc -swift-version 5 -default-isolation MainActor -parse-as-library \
  -module-cache-path "$work/ModuleCache" \
  Hours/City.swift Hours/CityTimeFormatter.swift Hours/AppTimeFormatPreference.swift \
  Hours/CitySearchItem.swift Hours/CitySearchDeduplicator.swift \
  "$work/Provider.swift" "$work/Rows.swift" \
  Tests/CitySearch/MapKitFakes.swift Tests/CitySearch/RegressionTests.swift \
  -o "$work/tests"
"$work/tests"
