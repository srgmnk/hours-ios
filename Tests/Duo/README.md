# Duo presentation regression tests

Run with an installed iOS simulator and Xcode 27.1:

```sh
python3 Tests/Duo/run.py SIMULATOR_UDID /private/tmp/Hours-DuoTests-run
```

The real-screen clock capture assumes the conventional iPhone's lower-left switcher. The inherited-safe-area rendering fixture requires a Duo display. Run all 53 cases across their intended devices, using fresh output directories:

```sh
python3 Tests/Duo/run.py DUO_UDID /private/tmp/Hours-DuoTests-layout -skip-testing:DuoTests/AnalogClockSwitcherTests/testClockTracksTheRealScreenThroughWheelAndPrimaryChanges -collect-test-diagnostics never
python3 Tests/Duo/run.py IPHONE_UDID /private/tmp/Hours-DuoTests-clock -only-testing:DuoTests/AnalogClockSwitcherTests/testClockTracksTheRealScreenThroughWheelAndPrimaryChanges -collect-test-diagnostics never
```

The clock fixture stops its periodic ticker and freezes inertia before changing the primary city, so unrelated model updates cannot hide a missed city-store notification. Its bounded visual wait retains the redraw assertion.

Use a fresh artifact directory. The runner copies the current working tree's app sources, generates an isolated XCTest host, and leaves all build products and results outside the repository. It does not change the production Xcode project or read/write the application's saved city collection. The temporary source copy removes access modifiers so the tests can inspect native view identity, layout attributes, and renderer lifecycle without adding production diagnostics.

The tests cover positive hinge gating, endpoint dimensions, reserved-region clearance, RTL, incomplete transition geometry, conventional map arithmetic, inner map crop, retained map/renderer identity, reversible visibility, and city-ID-based list scroll restoration across resizing and anchor deletion.

Simulator UI validation additionally requires real hinge endpoint changes through Device Hub. Geometry-only resizing is not evidence of hinge capability. Compare conventional List, Compact List, Map, empty, Settings, and Add City screenshots against a deterministic working-tree baseline before accepting a change. Wait for keyboard presentation to settle and compare the same caret-blink phase.
