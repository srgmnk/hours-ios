#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/../.."
artifact_dir=${1:-$(mktemp -d /private/tmp/Hours-CitySearchQuality.XXXXXX)}
python3 - "$artifact_dir" <<'PY'
from pathlib import Path
import hashlib, json, os, plistlib, shutil, sys
repo = Path.cwd()
out = Path(sys.argv[1]).resolve()
if out.is_relative_to(repo):
    raise SystemExit('Keep test artifacts outside the repository.')
work = out/'work'
if work.exists():
    raise SystemExit('Choose a fresh artifact directory.')
work.mkdir(parents=True)
source_paths = [
    'Hours/Models/City.swift', 'Hours/Features/Cities/CityTimeFormatter.swift',
    'Hours/Features/Settings/AppTimeFormatPreference.swift',
    'Hours/Features/Cities/Search/CitySearchItem.swift',
    'Hours/Features/Cities/Search/CitySearchDeduplicator.swift',
    'Hours/Features/Cities/Search/CityTimeZoneCompatibility.swift',
    'Hours/Services/Location/LocalCityCoordinates.swift',
    'Hours/Features/WorldMap/OriginalDecorativeCityIDs.swift',
    'Tests/CitySearch/MapKitFakes.swift', 'Tests/CitySearchQuality/QualityTests.swift',
]
hashes = {}
for path in source_paths:
    data = (repo/path).read_bytes()
    hashes[path] = hashlib.sha256(data).hexdigest()
    (work/Path(path).name).write_bytes(data)
provider_path = 'Hours/Features/Cities/Search/CitySearchProvider.swift'
provider = (repo/provider_path).read_text()
hashes[provider_path] = hashlib.sha256(provider.encode()).hexdigest()
(work/'Provider.swift').write_text(provider.replace('import MapKit\n', '').replace('private ', ''))
rows_path = 'Hours/Features/Cities/AddCitySheetView.swift'
source = (repo/rows_path).read_text()
hashes[rows_path] = hashlib.sha256(source.encode()).hexdigest()
start = source.index('    private struct DisplayResult:')
end = source.index('{', start) + 1
depth = 1
while depth:
    depth += (source[end] == '{') - (source[end] == '}')
    end += 1
(work/'Rows.swift').write_text('import Foundation\n'+source[start:end].replace('private struct', 'struct', 1))
source = (repo/'Tests/CitySearch/RegressionTests.swift').read_text()
source = source.replace('precondition(value, label)', 'if !value { FileHandle.standardError.write(Data(("FAIL existing: " + label + "\\n").utf8)) }; precondition(value, label)')
(work/'ExistingTests.swift').write_text(source.replace('@main struct RegressionTests', 'struct RegressionTests', 1))
shutil.copyfile(repo/'Hours/Resources/cities.json',work/'cities.json')
for path in (repo/'Tests/CitySearchQuality/Fixtures').glob('*.json'):
    shutil.copyfile(path,work/path.name)
resources = work/'original-catalog.bundle/Contents/Resources'
resources.mkdir(parents=True)
shutil.copyfile(repo/'Tests/CatalogIntegration/Fixtures/original-cities.json',resources/'cities.json')
(resources.parent/'Info.plist').write_bytes(plistlib.dumps({
    'CFBundleIdentifier':'ai.srgmnk.hours.tests.original-catalog', 'CFBundleName':'OriginalCatalog',
    'CFBundleVersion':'1','CFBundlePackageType':'BNDL'}))
baseline = os.environ.get('QUALITY_BASELINE_DIR')
if baseline:
    baseline = Path(baseline)
    old_provider = (baseline/'CitySearchProvider.swift').read_text()
    old_dedup = (baseline/'CitySearchDeduplicator.swift').read_text()
    (work/'BaselineProvider.swift').write_text(old_provider.replace('import MapKit\n','').replace('private ','').replace('CitySearchProvider','BaselineCitySearchProvider').replace('CitySearchDeduplicator','BaselineCitySearchDeduplicator'))
    (work/'BaselineDeduplicator.swift').write_text(old_dedup.replace('CitySearchDeduplicator','BaselineCitySearchDeduplicator'))
    (out/'baseline-source-hashes.json').write_text(json.dumps({
        'provider':hashlib.sha256(old_provider.encode()).hexdigest(),
        'deduplicator':hashlib.sha256(old_dedup.encode()).hexdigest()},indent=2)+'\n')
(out/'source-snapshot-hashes.json').write_text(json.dumps(hashes,indent=2)+'\n')
PY
defines=()
if [[ -n "${QUALITY_BASELINE_DIR:-}" ]]; then defines=(-D QUALITY_BASELINE); fi
xcrun swiftc -O -swift-version 5 -default-isolation MainActor -parse-as-library \
  -module-cache-path "$artifact_dir/work/ModuleCache" ${defines[@]+"${defines[@]}"} \
  "$artifact_dir"/work/*.swift -o "$artifact_dir/work/tests"
QUALITY_OUTPUT_DIR="$artifact_dir" "$artifact_dir/work/tests"
