# Live appearance regression coverage

Run on an installed iOS simulator with Xcode 27.1:

```sh
python3 Tests/Appearance/run.py SIMULATOR_UDID /private/tmp/Hours-AppearanceTests-run
```

Choose a fresh artifact directory under `/private/tmp`. The runner follows the existing isolated XCTest harness pattern: it copies the working tree's sources, exposes private types only in that disposable copy, and generates the test host/project outside the repository. The production project is unchanged. The production root test uses injected no-op storage; it never accesses the real app's saved cities or widget defaults.

Coverage includes the unchanged appearance key/default/override mapping, repeated UIKit trait changes reaching both SwiftUI colorScheme and AppTheme, manual Light/Dark overrides, rendered background pixels through the actual root and deferred screen geometry, and the existing map renderer/label trait observers. The probe also mounts the actual progressive blur and top-bar foreground modifier.

`SettingsAppearanceTests` presents the actual Settings sheet and changes the existing saved preference while it stays open. It covers every Light/Dark/System transition under both system appearances and both Settings headers, checking native navigation/title/Close traits, title foreground, retained presentation and scroll state, geometry, and reopening. It also changes live system traits after returning to System. Transition screenshots are retained in the XCTest result bundle.

The existing main-screen regression occurs when a parent theme is captured by a deferred screen builder. Observe the background and top-bar colors below that boundary. The Settings regression instead concerns the sheet's native presentation boundary. Do not add scene refreshes or replace view identities to make these checks pass.

Real-device checks remain necessary: on an iPhone with Appearance set to System, switch Light → Dark → Light repeatedly through Control Center, then repeat while backgrounded and returning through the app switcher. Inspect the main background, progressive blur, top-bar text/icons, dial, cards, Settings, and Add City. With manual Light and Dark, changing the system must leave the app's chosen appearance unchanged. Simulator trait injection does not prove the Control Center lifecycle path on a device.
