# Hours iOS — Comprehensive Code Audit

Audit date: October 25, 2026 (Asia/Bangkok)  
Scope: application, widget extension, project configuration, and intermittent time-wheel gesture failure  
Method: read-only source review, reference searches, SDK/documentation checks, and in-memory data checks

## 1. Executive summary

The read-only audit is complete. Several concrete defects were found, but the intermittent wheel freeze’s root cause remains unconfirmed. The strongest next step is to determine whether a failed drag reaches the wheel’s gesture callback at all.

The review covered all 37 Swift files—9,788 lines—plus project configuration, schemes, entitlements, asset references, and the 152-city dataset.

- No source files were modified, refactored, or reformatted during the audit. This Markdown report was subsequently created at the user’s request.
- The app was not built or launched, which would generate files and potentially change app data.
- The installed toolchain was Xcode 27.1, Apple Swift 6.4, and iOS SDK 27.1. Both targets deploy to iOS 26.0 and use Swift 5 language mode.
- SDK-sensitive conclusions were checked against installed headers and current Apple/Swift documentation.
- No unit-test or UI-test targets exist.
- Bundled city identifiers are unique, their time-zone identifiers resolve against the host database, and asset catalogs contain no missing referenced image files.
- The pre-existing `docs/HOURS_LEGAL_WEBVIEW_IMPLEMENTATION_AUDIT.md` was not changed.

The most important findings are missing wheel-cancellation cleanup, unsafe actor boundaries in callbacks, a persistence error path that can lead to saved-city loss, and missing privacy manifests. Several smaller correctness and performance problems are also confirmed.

**Evidence terminology:** “Confirmed” means the problematic code path is established by inspection; it does not imply that its user-visible manifestation was reproduced. A “hypothesis” requires runtime evidence before being treated as a root cause. Line numbers refer to the source as reviewed; links below are relative to this report for portability.

### Constraints and user observations

The audit preserves the existing architecture and UX. No implementation changes are included, and refactoring solely for cleanliness is not recommended.

The user reports that:

- On the latest iOS version, the time wheel intermittently becomes completely unresponsive to dragging.
- Opening and closing the Settings menu can sometimes restore functionality. In this implementation, the top-level Settings button presents a sheet.
- Deleting a city can occasionally restore functionality.
- It is not yet known whether recovery depends on deleting a particular city or the last city.
- The trigger is unknown and the issue is not consistently reproducible.
- An exact affected device and OS build were not supplied.

## 2. Critical issues

No critical issue—such as an established widespread crash or unavoidable data loss—was confirmed.

There are high-priority conditional risks, particularly persistence failure handling and actor-isolation violations.

## 3. High-priority issues

### H1 — Wheel drag state has no cancellation cleanup

- **Severity:** High.
- **Confidence:** High for the defect; medium as a contributor to the reported freeze.
- **Locations:** [TimeDialView.swift](../Hours/TimeDialView.swift), lines 19–20 and 93–156; [TimeDialScreen.swift](../Hours/TimeDialScreen.swift), lines 253–269; [TimeDialViewModel.swift](../Hours/TimeDialViewModel.swift), lines 57–85.

**Description and supporting evidence:** `dragStartAngle` is ordinary `@State`, cleared only by successful `.onEnded` or `resetSignal`. The parent’s `isDraggingSessionActive` is cleared only by the end callback. The model’s `isInteracting` has separate cleanup. There is no unified cancellation path, disappearance cleanup, or scene-inactivation cleanup.

Apple documents `.onEnded` as successful gesture completion; `GestureState` resets when a gesture becomes inactive. These are materially different lifecycle guarantees. See [Apple gesture documentation](https://developer.apple.com/documentation/SwiftUI/Adding-Interactivity-with-Gestures) and [GestureState](https://developer.apple.com/documentation/swiftui/gesturestate).

**Potential user impact:** An interrupted drag can leave an old angle baseline and session flag behind. The next drag may jump or skip initialization and inertia cancellation.

**Limitation:** The stale parent flag does **not** block `onDragChanged`. It therefore does not independently explain a wheel that receives no movement updates.

**Recommended minimal action:** Introduce one idempotent cancellation/finish operation covering child, parent, and model state. Track gesture activity with cancellation-aware state; distinguish cancellation from normal completion so cancellation does not start inertia. Explicitly handle scene and view lifecycle interruptions.

### H2 — A load failure can become permanent saved-city loss

- **Severity:** High.
- **Confidence:** High; conditional on a read or decoding failure.
- **Location:** [CityStore.swift](../Hours/CityStore.swift), lines 46–84 and 170–204.

**Description and supporting evidence:** Any load error sets `cities = []` and mirrors that empty collection to widget storage. The next city modification automatically calls `save()`, overwriting the original cities file with the replacement collection.

**Potential user impact:** A transient read failure or unsupported/corrupt record can make all saved cities disappear; adding a city afterward can overwrite recoverable data. Save failures are also invisible in release builds because logging is `#if DEBUG`.

**Recommended minimal action:** Distinguish “file absent” from “file could not be loaded.” Preserve the original file and widget snapshot on failure, and prevent silent replacement until recovery is resolved. Surface save failures instead of treating an in-memory edit as durable success.

### H3 — Background callbacks enter main-actor-isolated code directly

- **Severity:** High.
- **Confidence:** High for isolation violations; runtime/compiler consequences require validation.
- **Locations:** [ParallaxMotionManager.swift](../Hours/ParallaxMotionManager.swift), lines 25–35 and 57–59; [CityDetailsView.swift](../Hours/CityDetailsView.swift), lines 618–635.

**Description and supporting evidence:**

- Core Motion delivers updates on the custom operation queue, but the callback calls `self.clamp(...)`, a method of an `@MainActor` class, before entering `Task { @MainActor … }`.
- Notification authorization can complete on a background thread, but its callback directly calls `schedulePushNotification`, which belongs to the main-actor-isolated view.

The callback queues are documented by Apple: [Core Motion](https://developer.apple.com/documentation/coremotion/cmmotionmanager/startdevicemotionupdates(to:withhandler:)) and [notification authorization](https://developer.apple.com/documentation/usernotifications/unusernotificationcenter/requestauthorization(options:completionhandler:)).

**Potential user impact:** Concurrency diagnostics and possible runtime isolation failures, depending on compiler settings and generated checks. A crash in the current build was not established.

**Recommended minimal action:** Keep motion calculations explicitly nonisolated and based on captured immutable values, then publish on the main actor. Hop to the main actor before calling the notification helper, or use the async authorization API from a main-actor task. Do not change the project’s overall concurrency mode merely to suppress these problems.

### H4 — Required privacy manifests are absent

- **Severity:** High for distribution compatibility.
- **Confidence:** High for repository absence; archive contents were not inspected.
- **Locations:** [CityTimeFormatter.swift](../Hours/CityTimeFormatter.swift), line 98; [CityStore.swift](../Hours/CityStore.swift), lines 198–199; [AppIntent.swift](../HoursWidget/AppIntent.swift), lines 107–109.

**Description and supporting evidence:** Both executables access `UserDefaults`; no `.xcprivacy` file exists anywhere in the project tree, and no manifest-generation build step was found.

**Potential user impact:** App Store Connect acceptance risk. Apple requires declarations for covered APIs in each executable’s containing bundle. See [required-reason API requirements](https://developer.apple.com/documentation/bundleresources/describing-use-of-required-reason-api).

**Recommended minimal action:** Add appropriately targeted manifests after approval. The app’s own preferences and shared App Group storage correspond to different approved reasons; select declarations matching actual usage. See [UserDefaults reason categories](https://developer.apple.com/documentation/bundleresources/app-privacy-configuration/nsprivacyaccessedapitypes/nsprivacyaccessedapitype).

## 4. Medium- and low-priority issues

### M1 — Cancelled inertia still changes state

- **Severity:** Medium.
- **Confidence:** High, confirmed.
- **Location:** [TimeDialViewModel.swift](../Hours/TimeDialViewModel.swift), lines 131–159.
- **Description and evidence:** Cancellation exits the inertia loop, but execution always reaches `snapToNearestStep()` afterward.
- **Potential user impact:** An old task can snap or animate the wheel during a new drag. This is a logical ordering race on the main actor, not a simultaneous memory race.
- **Recommended minimal action:** Return on cancellation before the final snap; ensure an obsolete task cannot finish a newer interaction.

Task cancellation is cooperative. Cancelling a task does not skip code following its loop. See [Swift task cancellation](https://developer.apple.com/documentation/Swift/Task/cancel()).

### M2 — Ticker retains its view model indefinitely

- **Severity:** Medium.
- **Confidence:** High, confirmed.
- **Location:** [TimeDialViewModel.swift](../Hours/TimeDialViewModel.swift), lines 162–168; cancellation is only in `deinit`, lines 52–55.
- **Description and evidence:** The infinite ticker task captures `self`, and the owner relies on deinitialization to cancel that task.
- **Potential user impact:** The model cannot deinitialize through its intended cleanup path. It also continues publishing while the main screen is covered by sheets. The normal root-screen lifetime limits immediate leak growth.
- **Recommended minimal action:** Give the ticker an explicit lifecycle, or avoid retaining the owner across suspension. Cancel before releasing the owner.

### M3 — UIKit and SwiftUI city snapshots can temporarily overwrite one another

- **Severity:** Medium.
- **Confidence:** Medium; code-supported race hypothesis.
- **Location:** [TimeDialScreen.swift](../Hours/TimeDialScreen.swift), lines 449–452, 632–642, 902–913, 977–990, and 1016–1026.
- **Description and evidence:** Local edits are published through two asynchronous main-queue hops; pending external state is reapplied at reorder completion.
- **Potential user impact:** Old ordering can be reapplied before the binding catches up. Reloads may overlap deletion/reorder transitions. Flicker or inconsistent list state is plausible; a crash is **not established**.
- **Recommended minimal action:** Version snapshots or publish ID-based mutations so stale external state cannot replace a newer local edit. Validate the exact ordering before changing synchronization.

### M4 — Search merging permits duplicate SwiftUI identities

- **Severity:** Medium.
- **Confidence:** High for the defect; occurrence depends on search responses.
- **Locations:** [CitySearchProvider.swift](../Hours/CitySearchProvider.swift), lines 399–417; [AddCitySheetView.swift](../Hours/AddCitySheetView.swift), lines 41–45 and 120–122.
- **Description and evidence:** The merger simply appends local and remote results. The result view identifies rows by canonical identity.
- **Potential user impact:** If MapKit returns a locally matched city, two rows have the same `ForEach` ID, causing duplicate rows and unreliable row reconciliation.
- **Recommended minimal action:** Deduplicate by `canonicalIdentity` before applying the result limit. Do not deduplicate by time zone: different cities can legitimately share one.

### M5 — Search cancellation is not scoped to the cancelled request

- **Severity:** Medium.
- **Confidence:** High for missing ownership checks; medium for observable ordering failures.
- **Location:** [CitySearchProvider.swift](../Hours/CitySearchProvider.swift), lines 18–49 and 191–207.
- **Description and evidence:** A delayed cancellation handler cancels the shared completer and finishes whichever continuation is currently stored. A cancelled completion search can also fall through into another MapKit search.
- **Potential user impact:** Rapid typing can interfere with a newer request and launch unnecessary searches.
- **Recommended minimal action:** Associate continuation and cancellation cleanup with a request generation; check cancellation before each fallback stage.

### M6 — “My location” can resolve to a different city

- **Severity:** Medium.
- **Confidence:** High, confirmed logic.
- **Locations:** [CitySearchProvider.swift](../Hours/CitySearchProvider.swift), lines 271–281; [TimeDialScreen.swift](../Hours/TimeDialScreen.swift), lines 801–807.
- **Description and evidence:** Canonical lookup chooses the first same-time-zone city when city matching fails. The list also marks a sole time-zone match as current location.
- **Potential user impact:** A user in Pattaya can be offered Bangkok as their location. The bundled data and fallback order confirm that example.
- **Recommended minimal action:** Preserve the reverse-geocoded city when there is no actual city match; avoid treating equal time zones as equal locations.

### M7 — Weather/daylight coordinates can belong to the wrong city

- **Severity:** Medium.
- **Confidence:** High for insufficient validation; medium for particular MapKit outcomes.
- **Location:** [CityDetailsView.swift](../Hours/CityDetailsView.swift), lines 1151–1187 and 1432–1470.
- **Description and evidence:** Both providers search using city name alone, then accept a same-zone result or any valid coordinate.
- **Potential user impact:** Ambiguous city names can show another place’s weather and daylight, cached under the selected city’s ID.
- **Recommended minimal action:** Reject mismatched results; use available country/context to disambiguate. Share the validated coordinate lookup between the two providers.

### M8 — Daylight times shift incorrectly on DST transition days

- **Severity:** Medium.
- **Confidence:** High, confirmed date arithmetic.
- **Location:** [CityDetailsView.swift](../Hours/CityDetailsView.swift), line 1493 and lines 1543–1559.
- **Description and evidence:** The calculation produces local wall-clock minutes using noon’s offset, then adds them as elapsed seconds to local midnight.
- **Potential user impact:** Sunrise/sunset can be one hour wrong. An in-memory date check shows that 420 elapsed minutes from London midnight becomes 08:00 on March 29, 2026, and 06:00 on October 25, rather than 07:00.
- **Recommended minimal action:** Construct the event from local calendar components, or calculate its absolute UTC instant consistently.

### M9 — Every dial update reconfigures all visible city cells

- **Severity:** Medium.
- **Confidence:** High for redundant work; medium for performance impact.
- **Location:** [TimeDialScreen.swift](../Hours/TimeDialScreen.swift), line 697, lines 757–775, and 1215–1228.
- **Description and evidence:** `apply()` unconditionally replaces visible cells’ hosting configurations when other branches do not apply. Model updates also publish unchanged snapped values.
- **Potential user impact:** Avoidable formatting, layout and hosting work during dragging/inertia and idle ticks. This can cause jank, but no measured stall or permanent freeze is established.
- **Recommended minimal action:** Compare the inputs actually displayed before reconfiguring a cell; avoid publishing unchanged derived values. Profile before broader optimization.

### M10 — Widget timeline reads and decodes saved cities 720 times

- **Severity:** Medium.
- **Confidence:** High, confirmed.
- **Locations:** [HoursWidget.swift](../HoursWidget/HoursWidget.swift), lines 23–33; [AppIntent.swift](../HoursWidget/AppIntent.swift), lines 82–104.
- **Description and evidence:** Each of the 720 timeline entries independently resolves the selected city, reloading and decoding saved cities.
- **Potential user impact:** Unnecessary disk reads and decoding in the widget’s constrained execution budget.
- **Recommended minimal action:** Resolve the selected city once per timeline request and reuse it for every entry. Preserve the existing timeline cadence.

### M11 — Time-format preference is ignored in city details

- **Severity:** Medium.
- **Confidence:** High, confirmed inconsistency.
- **Locations:** [CityDetailsView.swift](../Hours/CityDetailsView.swift), lines 213–217 and 941–946; [CityTimeFormatter.swift](../Hours/CityTimeFormatter.swift), lines 39–57; [HoursWidget.swift](../HoursWidget/HoursWidget.swift), lines 57–61.
- **Description and evidence:** Details hardcode `HH:mm`; cards honor the selected time-format preference.
- **Potential user impact:** Selecting 12-hour format changes cards but leaves detail headers and daylight times in 24-hour format.
- **Recommended minimal action:** Route user-facing detail times through the existing preference-aware formatter. The widget also hardcodes 24-hour time; clarify its intended preference scope before changing it.

### M12 — Creation actions silently fail

- **Severity:** Medium.
- **Confidence:** High, confirmed.
- **Location:** [CityDetailsView.swift](../Hours/CityDetailsView.swift), lines 576–704.
- **Description and evidence:** Denied permissions, past notification dates, missing reminder calendars, and save errors return without feedback.
- **Potential user impact:** Users can believe a reminder/notification was created when it was not.
- **Recommended minimal action:** Report the specific failure and preserve the entered reminder title for retry.

### M13 — Wheel has no accessible adjustment action

- **Severity:** Medium.
- **Confidence:** High from source; verify with VoiceOver.
- **Location:** [TimeDialView.swift](../Hours/TimeDialView.swift), lines 35–156.
- **Description and evidence:** The control implements Canvas plus drag only, without semantic adjustment actions.
- **Potential user impact:** VoiceOver users have no equivalent semantic control for moving through time. This is separate from the intermittent touch bug.
- **Recommended minimal action:** Add a label, value and accessibility adjustment action using the same five-minute model updates, preserving visual UX.

### L1 — Deprecated and unreachable EventKit compatibility code

- **Severity:** Low.
- **Confidence:** High; confirmed against SDK headers.
- **Location:** [CityDetailsView.swift](../Hours/CityDetailsView.swift), lines 578–596 and 657–675.
- **Description and evidence:** The code uses `.authorized` and pre-iOS-17 fallback branches despite an iOS-26 minimum.
- **Potential user impact:** Unnecessary deprecated API exposure and misleading support paths.
- **Recommended minimal action:** Remove unreachable branches and use current access-level cases when fixes are approved.

Apple explicitly deprecates EventKit’s `.authorized` in favor of access-level checks. See [EventKit authorization](https://developer.apple.com/documentation/eventkit/ekauthorizationstatus/authorized).

### L2 — Legal pages fail blank without recovery

- **Severity:** Low.
- **Confidence:** High for missing handling; manifestation requires a failed load.
- **Location:** [LegalWebView.swift](../Hours/LegalWebView.swift), lines 11–28.
- **Description and evidence:** The web view loads a remote page without navigation-error handling or retry UI.
- **Potential user impact:** Offline or failed requests leave an unexplained empty sheet.
- **Recommended minimal action:** Add a small error/retry state while keeping the current web-view presentation.

## 5. Unused or obsolete code candidates

These are low-priority maintenance findings, not explanations for the production wheel freeze.

| Candidate | Location and supporting evidence | Impact and recommended minimal action | Confidence |
|---|---|---|---|
| Entire old SwiftUI list/reorder implementation | [TimeDialScreen.swift](../Hours/TimeDialScreen.swift), lines 1253–2349. `CityListView` has no construction site; its reorder controller, introspection, overlay and probes belong to that unused path. | Roughly 1,100 lines can misdirect debugging. Confirm there is no external consumer, then remove as a separate approved change. | High. |
| Flow-layout sizing callbacks on a compositional layout | [TimeDialScreen.swift](../Hours/TimeDialScreen.swift), lines 1074–1100; active layout is created at 527–545. | These callbacks do not govern the active compositional layout. Remove obsolete callbacks only; retain required collection-view delegate behavior. | High. |
| Unused dial-height measurement | [TimeDialScreen.swift](../Hours/TimeDialScreen.swift), line 23, lines 118–135 and 393–399. `dialHeight` is assigned but never read. | The comment says it controls list padding, but padding is actually fixed at 130 points. Remove the unused measurement after confirming that fixed behavior is intentional. | High. |
| Old time-zone deduplication helper | [CitySearchProvider.swift](../Hours/CitySearchProvider.swift), lines 507–518. No callers. | Do not revive it to fix M4; it would incorrectly collapse distinct cities. Remove after approval. | High. |
| Compatibility aliases and unused formatting helpers | [City.swift](../Hours/City.swift), lines 232–241; [EmptyStateQuote.swift](../Hours/EmptyStateQuote.swift), line 3; [CityTimeFormatter.swift](../Hours/CityTimeFormatter.swift), lines 65–68. No current consumers found. | Small maintenance burden. Remove only after checking intended external/API compatibility; initializer aliases do not provide JSON migration. | High within this project. |
| Unused drawing/theme inputs | [TimeDialView.swift](../Hours/TimeDialView.swift), lines 189–192 contain an unused `tickIndex` helper; lines 241–262 discard width selection. [AppTheme.swift](../Hours/AppTheme.swift), lines 31–32 declare `glassFill`/`glassBorder`, which have no consumers. | Can mislead future changes into editing values that have no effect. Low-priority removal only. | High. |

The repeated weather/daylight coordinate resolver is the duplication most worth addressing because it duplicates a real correctness problem. Repeated styling code alone does not justify refactoring.

## 6. Time wheel investigation

### 6.1 Complete active gesture path

1. [ContentView.swift](../Hours/ContentView.swift), lines 14–15, permits interaction after onboarding.
2. [TimeDialScreen.swift](../Hours/TimeDialScreen.swift), lines 65–125, layers the full-screen UIKit collection view, a noninteractive blur, and the dial overlay.
3. `TimeDialScreen.dialOverlay`, lines 245–285, positions a 512-point wheel partly below the screen and places the reset pill above it.
4. [TimeDialView.swift](../Hours/TimeDialView.swift), lines 92–95, gives the wheel a rectangular hit region and an ordinary `DragGesture(minimumDistance: 0)`.
5. Every change checks the start point against the global bottom boundary, invokes the parent’s guarded begin callback, computes an angle from the stored baseline, and forwards rotation.
6. [TimeDialViewModel.swift](../Hours/TimeDialViewModel.swift), lines 107–112, converts rotation to five-minute steps, updates the selected instant, and causes the list to reconfigure.
7. Successful completion clears gesture state and starts inertia.
8. [DeltaPillView.swift](../Hours/DeltaPillView.swift), lines 40–42, uses a high-priority tap to reset the model and increment `resetSignal`. It does not clear the parent session flag.

### 6.2 Relevant state dependencies

| Owner | State/input | Role and lifecycle concern |
|---|---|---|
| `ContentView` | `hasCompletedOnboarding` | Gates all main-screen hit testing. No evidence links it to intermittent failures after onboarding. |
| `TimeDialView` | `dragStartAngle`, `startRotationDegrees` | Local drag baseline; cancellation has no explicit cleanup. |
| `TimeDialScreen` | `isDraggingSessionActive` | Prevents repeated begin handling; does not gate rotation updates. |
| `TimeDialViewModel` | `isInteracting`, `baseTime`, `now` | Controls interaction anchoring and selected-time computation. |
| `TimeDialViewModel` | `rotationDegrees`, `dialSteps`, `deltaMinutes`, `selectedInstant` | Converts gesture movement into the wheel, pill and city times. |
| `TimeDialViewModel` | `inertiaTask` | Continues rotation after normal completion; cancelled tasks currently still snap. |
| `TimeDialViewModel` | `resetSignal` | Resets child baseline on change; does not reset the parent session flag. |
| Geometry | `maxInteractiveGlobalY`, current global wheel frame | Determines whether the drag is rejected as starting in the bottom dead zone. |
| `TimeDialScreen` | city emptiness and color scheme | Form the explicit identity of the subtree containing the wheel. |
| UIKit list controller | `isReordering`, `citiesLocal`, `pendingExternalState`, swipe state | Governs list movement and synchronization; no direct wheel-disable connection exists. |

### 6.3 Ranked potential causes

| Rank | Candidate | Supporting evidence and explanatory strength | Confidence and recommended next action |
|---|---|---|---|
| **1** | **Touch routing or recognizer arbitration involving the UIKit list/presentation hierarchy** | The wheel overlaps a full-screen collection view with pan, swipe-action and long-press behavior. Its drag uses ordinary priority. Settings presentation changes the presentation hierarchy without explicitly resetting wheel state; deletion changes collection layout and swipe state. This best fits recovery after otherwise unrelated actions. | **Medium, runtime hypothesis.** Capture the actual hit-test winner and recognizer states during failure. The list is a sibling, not a containing ScrollView, so interception must not be assumed. |
| **2** | **Cancelled drag leaves inconsistent state across three owners** | H1 establishes the cleanup gap. It explains stale baselines and skipped initialization, especially after interruption. | **High defect confidence; medium fit to symptoms.** Observe child baseline, parent session flag and model interaction flag together. It does not alone explain absent change callbacks. |
| **3** | **Layout/global-coordinate mismatch around presentation transitions** | The dead-zone guard combines local gesture start coordinates with the wheel’s current global frame on every callback. Sheet presentation changes geometry. | **Low–medium.** If callbacks arrive but return at the guard, record both frames and the derived global start Y. No evidence yet that the boundary becomes incorrect. |
| **4** | **Main-thread pressure from repeated hosting configuration and formatting** | M9 provides a concrete expensive update path during drag/inertia. Deleting a city reduces some work. | **Medium for jank; low for a persistent freeze.** Profile a failure. Settings recovery and indefinite unresponsiveness are not well explained by ordinary rendering cost. |
| **5** | **Cancelled inertia or reset animation interfering with a new gesture** | M1 establishes a competing state write; reset and snap use spring transactions. | **High defect confidence; low fit to complete touch loss.** Record task generations and writes. Likely to explain jumps or brief interference, not a permanently dead recognizer. |

All five concern a **high-impact symptom**, but only the cancellation and inertia defects are established from source. None is a confirmed root cause.

### 6.4 Why Settings or city deletion might restore functionality

- **Settings open/close:** Changes presentation state and geometry. There is no explicit wheel reset, cancellation repair or identity change in this action. Recovery would support a presentation/recognizer/layout explanation, but runtime inspection is necessary.
- **Deleting a nonfinal city:** Performs collection-view batch deletion and publishes a changed collection. It does not change the wheel subtree’s explicit ID.
- **Deleting the last city:** Changes the outer ID from `list-…` to `empty-…` at [TimeDialScreen.swift](../Hours/TimeDialScreen.swift), line 161. This recreates the subtree containing `TimeDialView`, its local state and gesture. The screen-owned model and session flag sit outside that identity boundary.
- **Changing appearance:** Also changes that subtree ID and recreates the wheel. Merely opening Settings does not.

### 6.5 Evidence against tempting explanations

- The progressive blur explicitly disables hit testing both internally and at its call site.
- The old SwiftUI reorder overlay and its custom hit-test probe are unused; their gesture behavior cannot explain the active screen.
- The reset pill can compete within its own hit area, but source inspection does not show it covering the entire wheel.
- No active code disables the wheel based on `isInteracting` or `isDraggingSessionActive`.
- A normal SwiftUI body update is not equivalent to recreating the wheel’s identity.

### 6.6 Recent iOS behavior and compatibility

Apple documented changes to priority relationships between SwiftUI gestures and UIKit recognizers in iOS 26. That makes SDK-linked arbitration worth testing, but does not establish an OS bug here. See [iOS 26 release notes](https://developer.apple.com/documentation/ios-ipados-release-notes/ios-ipados-26-release-notes).

No retrieved release-note evidence identified this exact intermittent freeze. The iOS 27.1 release-note page was not accessible through the documentation lookup, so an undocumented or more recent framework issue cannot be ruled out.

The code was reviewed with the current main-actor default and approachable-concurrency settings in mind. Swift 5 language mode should not be mistaken for use of a Swift 5 compiler; the installed compiler was Swift 6.4. No compiler-validation result is claimed because a build was not run.

## 7. Recommended debugging steps

The first reproduction should distinguish **missing touches**, **rejected callbacks**, and **successful model updates that fail to render**.

1. **Observe before repairing the frozen state.** Use debugger breakpoints/logpoints at `TimeDialView.onChanged`, the dead-zone guard, `updateDialRotation`, and `.onEnded`. These can be configured without editing source.
2. **Inspect all gesture state together:** `dragStartAngle`, `startRotationDegrees`, `isDraggingSessionActive`, `isInteracting`, `rotationDegrees`, `dialSteps`, and `resetSignal`.
3. **Capture the view hierarchy during failure.** Inspect the wheel’s frame and the views above it, including collection swipe-action and sheet-presentation views. Compare the same screen coordinate before and after Settings dismissal.
4. **Inspect recognizers.** Record state, owning view, enabled status and failure relationships for the wheel gesture, collection pan, reorder long press, and active presentation recognizers.
5. **Profile only if callbacks continue.** If `onChanged` and rotation updates arrive normally, use Time Profiler/SwiftUI instruments to inspect hosting configuration, formatting and layout work.

### Targeted reproduction scenarios

| Scenario | What it distinguishes |
|---|---|
| Drag while opening Control Center, switching apps, or locking/unlocking | Cancellation cleanup and scene transitions. |
| Leave a city’s swipe actions exposed, then drag the wheel | UIKit swipe-state interception. |
| Drag immediately after ending or cancelling city reorder | Pending city snapshots and recognizer transitions. |
| Open and close Settings without changing anything | Presentation effects independent of explicit wheel reset. |
| Change appearance while Settings is open | Explicit subtree reconstruction. |
| Compare deleting a middle city with deleting the final city | Collection updates versus wheel identity replacement. |
| Flick, then immediately drag again; separately flick then tap reset | Obsolete inertia writes. |
| Compare drags on visible ticks, empty wheel space, the pill, and the bottom 16 points | Actual hit regions and intentional dead zone. |
| Repeat with zero, one and many cities, in both card sizes | UIKit-list involvement and rendering cost. |

Record exact device, OS build, build SDK, appearance, city count, and whether the reset pill still responds. Compare the **same app binary** across OS versions before attributing a difference to SDK-linked behavior.

The existing `[DIAL] drag begin` log is insufficient: a stale session flag suppresses it even when change callbacks still arrive. Also, the elaborate existing hit-test probe belongs to the unused list implementation.

### Diagnostic interpretation

| Observation during failure | Next investigation |
|---|---|
| No `onChanged` callback | Hit-test winner, recognizer arbitration, covering presentation views, and recognizer lifecycle. |
| `onChanged` arrives but the dead-zone guard rejects it | Global/local frame consistency and presentation geometry. |
| Callback reaches `onDragChanged`, but initialization is skipped | Parent session flag and child baseline left over from cancellation. |
| Rotation is written and immediately changed again | Inertia ownership, cancellation and reset/snap transactions. |
| Rotation changes correctly but the screen does not update | Main-thread work, hosting/layout updates and rendering. |

## 8. Minimal proposed fixes — none implemented

Recommended order:

1. Add coherent wheel cancellation cleanup and prevent cancelled inertia from snapping.
2. Fix the two callback actor boundaries.
3. Protect saved cities from load-error replacement.
4. Add required privacy declarations.
5. Correct DST event-date construction and canonical search deduplication.
6. Scope search cancellation to request generations.
7. Eliminate the widget’s repeated storage reads; profile before changing the broader rendering path.
8. Address location identity, time-format consistency and silent action failures with narrowly scoped changes.

For the freeze specifically, **do not yet switch every gesture to high priority, enable simultaneous recognition indiscriminately, or force a new wheel ID after every UI action**. Those changes could conceal the failure or interfere with scrolling, swipe actions and reset behavior. First establish which layer stops receiving or processing the touch.

Any implementation should preserve the existing architecture and visual UX, and validate normal completion, cancellation, immediate re-drag, reset during inertia, Settings presentation, and city-list changes separately.
