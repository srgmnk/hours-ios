#!/usr/bin/env python3
"""Build isolated iOS appearance tests without adding targets to Hours.xcodeproj.
Usage: python3 Tests/Appearance/run.py SIMULATOR_UDID [ARTIFACT_DIRECTORY]
"""
from pathlib import Path
import plistlib
import shutil
import subprocess
import sys
import tempfile

repo = Path(__file__).resolve().parents[2]
out = Path(sys.argv[2]) if len(sys.argv) > 2 else Path(tempfile.mkdtemp(prefix='Hours-AppearanceTests-', dir='/private/tmp'))
if not out.resolve().is_relative_to(Path('/private/tmp')):
    raise SystemExit('Keep all generated appearance-test artifacts under /private/tmp.')
out.mkdir(parents=True, exist_ok=True)
app = out / 'App'
if app.exists():
    raise SystemExit('Choose a fresh artifact directory; existing harnesses are never overwritten.')
shutil.copytree(repo / 'Hours', app)
for name in ['SupportingFiles/Info.plist', 'SupportingFiles/Hours.entitlements']:
    (app / name).unlink(missing_ok=True)
# Tests inspect the themed root and native trait observers. Only access control changes in
# these disposable source copies; production encapsulation and layout stay intact.
for path in app.rglob('*.swift'):
    path.write_text(path.read_text().replace('fileprivate ', '').replace('private ', ''))
# Retain the actual themed root for preference/hosting integration coverage.
entry = app / 'App/HoursApp.swift'
source = entry.read_text()
entry.write_text(source[source.index('struct ThemedRootView:'):])
entry.write_text('import SwiftUI\n' + entry.read_text())
(app / 'TestApp.swift').write_text('import SwiftUI\n@main struct AppearanceTestApp: App { var body: some Scene { WindowGroup { Color.clear } } }\n')
tests = out / 'UnitTests'; tests.mkdir()
for path in Path(__file__).parent.glob('*Tests.swift'):
    shutil.copy2(path, tests / path.name)
objects = {}
serial = 0

def obj(isa, **fields):
    global serial
    serial += 1
    key = f'{serial:024X}'
    objects[key] = dict(isa=isa, **fields)
    return key

def configs(settings):
    values = [obj('XCBuildConfiguration', name=name, buildSettings={**settings, 'SWIFT_OPTIMIZATION_LEVEL': '-Onone' if name == 'Debug' else '-O'}) for name in ['Debug', 'Release']]
    return obj('XCConfigurationList', buildConfigurations=values, defaultConfigurationIsVisible=0, defaultConfigurationName='Debug')

common = dict(SDKROOT='iphoneos', IPHONEOS_DEPLOYMENT_TARGET='26.0', SWIFT_VERSION='5.0', SWIFT_DEFAULT_ACTOR_ISOLATION='MainActor', CLANG_ENABLE_MODULES='YES', ENABLE_TESTABILITY='YES', CODE_SIGNING_ALLOWED='NO', TARGETED_DEVICE_FAMILY='1', GENERATE_INFOPLIST_FILE='YES', SWIFT_ACTIVE_COMPILATION_CONDITIONS='DEBUG')
app_group = obj('PBXFileSystemSynchronizedRootGroup', path='App', sourceTree='<group>')
test_group = obj('PBXFileSystemSynchronizedRootGroup', path='UnitTests', sourceTree='<group>')
app_ref = obj('PBXFileReference', explicitFileType='wrapper.application', path='MapHarness.app', sourceTree='BUILT_PRODUCTS_DIR')
test_ref = obj('PBXFileReference', explicitFileType='wrapper.cfbundle', path='AppearanceTests.xctest', sourceTree='BUILT_PRODUCTS_DIR')
products = obj('PBXGroup', children=[app_ref, test_ref], name='Products', sourceTree='<group>')
main = obj('PBXGroup', children=[app_group, test_group, products], sourceTree='<group>')

def phases():
    return [obj(isa, buildActionMask=2147483647, files=[], runOnlyForDeploymentPostprocessing=0) for isa in ['PBXSourcesBuildPhase', 'PBXFrameworksBuildPhase', 'PBXResourcesBuildPhase']]

app_target = obj('PBXNativeTarget', name='MapHarness', productName='MapHarness', productReference=app_ref, productType='com.apple.product-type.application', buildConfigurationList=configs({**common, 'PRODUCT_NAME': 'MapHarness', 'PRODUCT_BUNDLE_IDENTIFIER': 'com.hours.appearance.tests.host', 'INFOPLIST_KEY_UILaunchScreen_Generation': 'YES', 'INFOPLIST_KEY_UISupportedInterfaceOrientations': 'UIInterfaceOrientationPortrait'}), buildPhases=phases(), buildRules=[], dependencies=[], fileSystemSynchronizedGroups=[app_group])
project = obj('PBXProject', attributes={'LastUpgradeCheck': '2710'}, buildConfigurationList=configs(common), compatibilityVersion='Xcode 16.0', developmentRegion='en', knownRegions=['en', 'Base'], mainGroup=main, productRefGroup=products, projectDirPath='', projectRoot='', targets=[])
proxy = obj('PBXContainerItemProxy', containerPortal=project, proxyType=1, remoteGlobalIDString=app_target, remoteInfo='MapHarness')
dependency = obj('PBXTargetDependency', target=app_target, targetProxy=proxy)
test_target = obj('PBXNativeTarget', name='AppearanceTests', productName='AppearanceTests', productReference=test_ref, productType='com.apple.product-type.bundle.unit-test', buildConfigurationList=configs({**common, 'PRODUCT_NAME': 'AppearanceTests', 'PRODUCT_BUNDLE_IDENTIFIER': 'com.hours.appearance.tests.unit', 'TEST_HOST': '$(BUILT_PRODUCTS_DIR)/MapHarness.app/MapHarness', 'BUNDLE_LOADER': '$(TEST_HOST)'}), buildPhases=phases(), buildRules=[], dependencies=[dependency], fileSystemSynchronizedGroups=[test_group])
objects[project]['targets'] = [app_target, test_target]
project_dir = out / 'AppearanceTests.xcodeproj'; project_dir.mkdir()
(project_dir / 'project.pbxproj').write_bytes(plistlib.dumps(dict(archiveVersion='1', classes={}, objectVersion='77', objects=objects, rootObject=project)))
schemes = project_dir / 'xcshareddata/xcschemes'; schemes.mkdir(parents=True)
ref = lambda target, name, product: f'<BuildableReference BuildableIdentifier="primary" BlueprintIdentifier="{target}" BuildableName="{product}" BlueprintName="{name}" ReferencedContainer="container:AppearanceTests.xcodeproj"/>'
(schemes / 'AppearanceTests.xcscheme').write_text(f'''<?xml version="1.0" encoding="UTF-8"?>
<Scheme LastUpgradeVersion="2710" version="1.3">
<BuildAction parallelizeBuildables="YES" buildImplicitDependencies="YES"><BuildActionEntries>
<BuildActionEntry buildForTesting="YES" buildForRunning="YES" buildForProfiling="YES" buildForArchiving="YES" buildForAnalyzing="YES">{ref(app_target,'MapHarness','MapHarness.app')}</BuildActionEntry>
</BuildActionEntries></BuildAction>
<TestAction buildConfiguration="Debug" selectedDebuggerIdentifier="Xcode.DebuggerFoundation.Debugger.LLDB" selectedLauncherIdentifier="Xcode.IDEFoundation.Launcher.LLDB" shouldUseLaunchSchemeArgsEnv="YES"><Testables><TestableReference skipped="NO">{ref(test_target,'AppearanceTests','AppearanceTests.xctest')}</TestableReference></Testables></TestAction>
<LaunchAction buildConfiguration="Debug" selectedDebuggerIdentifier="Xcode.DebuggerFoundation.Debugger.LLDB" selectedLauncherIdentifier="Xcode.IDEFoundation.Launcher.LLDB"><BuildableProductRunnable runnableDebuggingMode="0">{ref(app_target,'MapHarness','MapHarness.app')}</BuildableProductRunnable></LaunchAction>
</Scheme>''')
print(f'Artifacts: {out}', flush=True)
command = ['xcodebuild', '-project', str(project_dir), '-scheme', 'AppearanceTests', '-destination', f'platform=iOS Simulator,id={sys.argv[1]}', '-derivedDataPath', str(out / 'Build'), '-resultBundlePath', str(out / 'Results.xcresult'), 'test', 'ARCHS=arm64']
with (out / 'tests.log').open('w') as log:
    result = subprocess.run(command, stdout=log, stderr=subprocess.STDOUT)
print((out / 'tests.log').read_text()[-2500:])
sys.exit(result.returncode)
