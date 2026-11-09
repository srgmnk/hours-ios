#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/../.."
work=$(mktemp -d /private/tmp/Hours-CatalogIntegration.XXXXXX)
trap 'rm -rf "$work"' EXIT
python3 - "$work" <<'PY'
from pathlib import Path
import sys, plistlib, shutil
out=Path(sys.argv[1])
provider=Path('Hours/Features/Cities/Search/CitySearchProvider.swift').read_text()
(out/'Provider.swift').write_text(provider.replace('import MapKit\n','').replace('private ',''))
def extract(source,marker):
    start=source.index(marker);brace=source.index('{',start);depth=1;end=brace+1
    while depth:depth+=(source[end]=='{')-(source[end]=='}');end+=1
    return source[start:end]
source=Path('Hours/Features/Cities/AddCitySheetView.swift').read_text()
(out/'Rows.swift').write_text('import Foundation\n'+extract(source,'    private struct DisplayResult:').replace('private struct','struct',1))
source=Path('Hours/Features/Cities/CityStore.swift').read_text()
methods=[extract(source,'    private func migratedCanonicalID('),extract(source,'    private func customReferenceCanonicalIDIfNeeded(')]
(out/'StoreIdentityProbe.swift').write_text('import Foundation\n@MainActor final class StoreIdentityProbe {\n let provider: CitySearchProvider\n init(provider: CitySearchProvider) { self.provider=provider }\n'+'\n'.join(methods).replace('private ','').replace('CitySearchProvider.shared','provider')+'\n}\n')
source=Path('Hours/Features/WorldMap/WorldMapView.swift').read_text()
(out/'Projection.swift').write_text('import Foundation\n'+extract(source,'private enum WorldMapProjection').replace('private enum','enum',1)+'\n')
source=Path('Tests/CitySearch/RegressionTests.swift').read_text()
(out/'ExistingRegressionTests.swift').write_text(source.replace('@main struct RegressionTests','struct RegressionTests',1))
for fixture in Path('Tests/CatalogIntegration/Fixtures').glob('*.json'):shutil.copyfile(fixture,out/fixture.name)
shutil.copyfile('Hours/Resources/cities.json',out/'cities.json')
resources=out/'original-catalog.bundle/Contents/Resources';resources.mkdir(parents=True)
shutil.copyfile('Tests/CatalogIntegration/Fixtures/original-cities.json',resources/'cities.json')
(out/'original-catalog.bundle/Contents/Info.plist').write_bytes(plistlib.dumps({'CFBundleIdentifier':'ai.srgmnk.hours.tests.original-catalog','CFBundleName':'OriginalCatalog','CFBundleVersion':'1','CFBundlePackageType':'BNDL'}))
PY
xcrun swiftc -swift-version 5 -default-isolation MainActor -parse-as-library \
  -module-cache-path "$work/ModuleCache" \
  Hours/Models/City.swift Hours/Features/Cities/CityStore.swift Hours/Features/Cities/CityTimeFormatter.swift Hours/Features/Settings/AppTimeFormatPreference.swift \
  Hours/Features/Cities/Search/CitySearchItem.swift Hours/Features/Cities/Search/CitySearchDeduplicator.swift Hours/Features/Cities/Search/CityTimeZoneCompatibility.swift \
  Hours/Services/Location/LocalCityCoordinates.swift Hours/Services/Location/LegacyCityCoordinateResolver.swift \
  Hours/Features/WorldMap/OriginalDecorativeCityIDs.swift Hours/Features/WorldMap/NightCityLights.swift Hours/Services/SolarPosition.swift \
  "$work/Provider.swift" "$work/Rows.swift" "$work/StoreIdentityProbe.swift" "$work/Projection.swift" \
  Tests/CitySearch/MapKitFakes.swift "$work/ExistingRegressionTests.swift" Tests/CatalogIntegration/IsolatedCityStoreFixture.swift Tests/CatalogIntegration/IntegrationTests.swift \
  -o "$work/tests"
"$work/tests"
