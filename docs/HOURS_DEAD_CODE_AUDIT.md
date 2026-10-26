# Hours — Focused Dead-Code Audit

Date: 25 October 2026  
Scope: current working-tree source, with the recent compatibility, cancellation, persistence, actor-isolation, search, geographical-evidence, and Current Location corrections present.  
Status: **read-only source investigation; no removals or production changes implemented.** Only this report was added.

## 1. Executive findings

**The old SwiftUI city-list implementation is confirmed unreachable in the current application.** Its complete, self-contained removal range is [TimeDialScreen.swift](/Users/srgmnk/Library/CloudStorage/Dropbox/Xcode/Timie/Hours/TimeDialScreen.swift:1369), **lines 1369–2465: 1,097 physical lines**, including comments and separating blank lines. This is approximately 44.5% of the current 2,465-line file.

The active screen constructs `CityListReorderUIKitView`, not `CityListView`. Every reference to the legacy list's controller, measurement keys, introspection views, long-press driver, hit-test probes, and diagnostic switches is inside the legacy block. No app entry point, widget, preview, target setting, resource, or dynamic lookup connects that block to production execution.

Three additional small groups are confirmed unused: an old details-header formatter and its private formatter instance (10 lines), an uncalled private wheel helper (4 lines), and unread theme properties plus their initializer arguments (6 lines). They are independent, lower-priority changes and should not be combined with the legacy-list removal.

**Estimated confirmed removal size: 1,117 physical lines**, consisting of the 1,097-line list block plus those 20 lines. This estimate excludes active measurement callbacks, Objective-C delegate callbacks requiring verification, compatibility aliases, imports, and all recently added fixes.

The dial-height measurement is **active but has an unread output**. It is not equivalent to the unreachable list and is excluded from the initial safe-removal recommendation. The three flow-layout delegate methods are also excluded pending runtime verification of indirect framework calls.

## 2. Evidence and classification method

The audit searched all **37 Swift source files: 34 in Hours and 3 in HoursWidget**, plus repository text, target configuration, shared schemes, the launch storyboard, and conditional-compilation branches. Documentation mentions were distinguished from executable references.

Checks included:

- Construction sites, stored properties, function references, closures, extensions, protocol conformances, and SwiftUI property wrappers.
- All occurrences of each legacy type and diagnostic switch, not merely `TypeName()` expressions.
- `#if DEBUG`, simulator branches, SwiftUI previews, Objective-C selectors, UIKit delegate registration, and view lifecycle overrides.
- Searches for `NSClassFromString`, `NSSelectorFromString`, string selectors, `_typeByName`, `Mirror`, class lookup, archive decoding, and storyboard custom classes. No dynamic lookup or resource registration referring to the legacy types was found.
- Xcode synchronized-folder membership: the app uses `Hours`; the extension uses `HoursWidget`. The two shared app schemes point to the same Hours target. Neither has an alternative legacy-list construction path. There is no configured test target or package dependency exposing these internal declarations as a public library API.

The launch storyboard uses ordinary UIKit objects and does not instantiate these classes. The existing `CityDetailsView_Previews` constructs `CityDetailsView`, not a legacy list. No other preview entry point references the candidates.

Classification:

1. **Confirmed unused:** unreachable in the inspected repository's target and runtime construction graph, or an uncalled ordinary Swift helper with no dynamic dispatch path.
2. **Probably unused / verification required:** no useful output or expected framework caller, but active callbacks, view graph effects, or intent prevent a strict zero-behavior-change claim.
3. **Still active:** reached from the production screen, framework callbacks, or a registered closure.
4. **Intentionally retained compatibility code:** a documented compatibility surface, or a recently authorized retained-data mechanism, which must not be removed based on reference counts alone.

This is a focused reachability audit of the legacy list and previously identified small candidates, not a claim that every unrelated declaration in the project has been exhaustively proven live or dead. No source-copy deletion experiment, new build, or device test was performed during this read-only audit. Build and runtime validation below are requirements for a future removal, not completed cleanup validation.

### Active production path

```text
HoursApp → ThemedRootView → ContentView → TimeDialScreen
  → GeometryReader
    → TimeDialObservedContent (@ObservedObject: the existing @StateObject model)
      → nonempty: CityListReorderUIKitView
          → CityListReorderViewController
            → UICollectionView + registered header/cell classes
              → UIHostingConfiguration → CityCardView
      → empty: MainEmptyStateQuoteView + ShakeDetectorView
      → dialOverlay → TimeDialView + DeltaPillView
```

Relevant construction evidence: [ContentView.swift:14](/Users/srgmnk/Library/CloudStorage/Dropbox/Xcode/Timie/Hours/ContentView.swift:14), [TimeDialScreen.swift:71](/Users/srgmnk/Library/CloudStorage/Dropbox/Xcode/Timie/Hours/TimeDialScreen.swift:71), [77](/Users/srgmnk/Library/CloudStorage/Dropbox/Xcode/Timie/Hours/TimeDialScreen.swift:77), [108](/Users/srgmnk/Library/CloudStorage/Dropbox/Xcode/Timie/Hours/TimeDialScreen.swift:108), [576](/Users/srgmnk/Library/CloudStorage/Dropbox/Xcode/Timie/Hours/TimeDialScreen.swift:576), and [1332](/Users/srgmnk/Library/CloudStorage/Dropbox/Xcode/Timie/Hours/TimeDialScreen.swift:1332).

The legacy `CityListView` name occurs once in Swift source: its declaration at line 1369. There is no initializer call, metatype reference, extension adding an entry point, or runtime registration for it.

## 3. Confirmed unused: legacy list and its exclusive dependencies

All rows in this table refer to **TimeDialScreen.swift**. Counts are inclusive physical-line counts. Confidence is **high** and expected behavior regression risk is **low** for each row, provided removal stays within the stated range and all still-referenced dependencies are removed in the same group or later.

| Declaration / group | Current lines | Lines | Reference evidence | Dependencies removable with this group | Specific risk |
|---|---:|---:|---|---|---|
| `CityListView` | [1369–1763](/Users/srgmnk/Library/CloudStorage/Dropbox/Xcode/Timie/Hours/TimeDialScreen.swift:1369) | 395 | Declaration only; no construction site in app, widget, previews, or resources. | All state, layout, overlays, animations, callback closures, haptics, timers, and private methods listed below; then its exclusive support types. | Do not confuse this with the active `CityListReorderUIKitView`. |
| `ReorderController` | [1765–2070](/Users/srgmnk/Library/CloudStorage/Dropbox/Xcode/Timie/Hours/TimeDialScreen.swift:1765) | 306 | Only construction is legacy `CityListView` line 1377. No independent allocation or dynamic lookup. | Published reorder state, scroll observation, auto-scroll, index calculation, commit/cancel/reset, diagnostic timestamps. | The active UIKit controller has separate reorder state and must remain. |
| `CityRowFramePreferenceKey` | [2072–2078](/Users/srgmnk/Library/CloudStorage/Dropbox/Xcode/Timie/Hours/TimeDialScreen.swift:2072) | 7 | Only writer/reader: legacy lines 1410 and 1474. | Default value and `reduce` witness. | Not `DialOverlayHeightPreferenceKey`, which is used by the active screen. |
| `ScrollViewIntrospector` | [2080–2091](/Users/srgmnk/Library/CloudStorage/Dropbox/Xcode/Timie/Hours/TimeDialScreen.swift:2080) | 12 | Only construction: legacy line 1426. | Representable lifecycle methods; `ScrollIntrospectionView` once wrapper is removed. | No active UIKit-list dependency. |
| `ScrollIntrospectionView` | [2093–2186](/Users/srgmnk/Library/CloudStorage/Dropbox/Xcode/Timie/Hours/TimeDialScreen.swift:2093) | 94 | References only in `ScrollViewIntrospector`, lines 2083, 2084, 2087. | Window/superview callbacks, deferred retry, ancestor/descendant traversal, hit-test search. | UIKit overrides are live only if this unused wrapper constructs an instance. |
| `ScrollViewHolder` | [2188–2198](/Users/srgmnk/Library/CloudStorage/Dropbox/Xcode/Timie/Hours/TimeDialScreen.swift:2188) | 11 | Only construction: legacy line 1378. | Published scroll-view reference and `setIfChanged`. | Do not remove unrelated observable owners. |
| `RowLongPressDriverModifier` | [2200–2223](/Users/srgmnk/Library/CloudStorage/Dropbox/Xcode/Timie/Hours/TimeDialScreen.swift:2200) | 24 | Only application: legacy row line 1595. | Overlay and forwarding callbacks; the two driver types below. | This is the old row gesture, not the wheel gesture. |
| `RowLongPressDriverView` | [2225–2251](/Users/srgmnk/Library/CloudStorage/Dropbox/Xcode/Timie/Hours/TimeDialScreen.swift:2225) | 27 | Only construction: modifier line 2210. | Representable make/update methods. | Remove together with its caller or after the caller. |
| `RowLongPressDriverUIView` | [2253–2389](/Users/srgmnk/Library/CloudStorage/Dropbox/Xcode/Timie/Hours/TimeDialScreen.swift:2253) | 137 | Only wrapper references: lines 2235, 2236, 2239. Selector registration at 2255 belongs to this never-created instance. | Long-press recognizer, four callbacks, scroll-coordinate conversion, simultaneous-recognition delegate, diagnostic flags. | Do not remove active `CityListReorderViewController.handleLongPress` or `TimeDialView.cancelDrag`. |
| `HitTestProbeView` including its leading comment | [2391–2408](/Users/srgmnk/Library/CloudStorage/Dropbox/Xcode/Timie/Hours/TimeDialScreen.swift:2391) | 18 | Only construction: legacy overlay line 1570. | Representable lifecycle and probe payload. | Identical diagnostic wording elsewhere does not imply shared ownership. |
| `HitTestProbeUIView` | [2410–2448](/Users/srgmnk/Library/CloudStorage/Dropbox/Xcode/Timie/Hours/TimeDialScreen.swift:2410) | 39 | Only wrapper references: lines 2397, 2398, 2403. | Hit-test overrides, recursion guard, throttling state, logging. | No independent window/view registration. |
| `ENABLE_SCROLL_PROBE`, `ENABLE_CITYLIST_DEBUG`, `DISABLE_REORDER`, `cityListDebugLog` | [2450–2465](/Users/srgmnk/Library/CloudStorage/Dropbox/Xcode/Timie/Hours/TimeDialScreen.swift:2450) | 16 | Every use is at line 1369 or later. Both DEBUG and non-DEBUG definitions serve only the legacy implementation. | Entire conditional-definition block and logger. | Preserve active `[SCROLLPROBE]`, `[REORDER_UIKIT]`, and `[DIAL]` diagnostics elsewhere. |

The declaration/group counts total **1,086 lines**. The **11 separating blank lines** bring the contiguous deletion range to **1,097 lines**. These are alternative ways of counting the same group, not additive estimates.

### State and callback inventory inside `CityListView`

The following are all members of the unreachable view and are included in its 395-line count:

- Inputs/environment, lines 1370–1375: `theme`, `cities`, `selectedInstant`, `currentCity`, `topSafeAreaInset`, `bottomContentInset`.
- Owners, lines 1377–1378: `reorderController`, `scrollViewHolder`.
- State, lines 1379–1391: `lastGlobalRowFrames`, `lastGlobalRowFramesHash`, `rowFrames`, `pendingRowFrames`, `rowFramesCommitScheduled`, `activeRowFramesSnapshot`, `beginContentOffsetY`, `hasContentSpaceRowFrames`, `lastRowFramesHash`, `didLogReorderDataNotReady`, `scrollViewport`, `lastContentProbeHeight`, `lastViewportProbeHeight`.
- Layout and feedback, lines 1393–1398: `cardHeight`, `cardSpacing`, `horizontalPadding`, `reorderStartHaptics`, `reorderDropHaptics`, `autoScrollTimer`.
- `body`, lines 1400–1578: old `ScrollView`/`LazyVStack`, row-frame preferences, spring animations, scroll introspection, floating dragged-card overlay, preference/Combine callbacks, 60 Hz auto-scroll subscription, lifecycle cleanup, and debug hit-test overlay.
- `rowView`, lines 1580–1640: old row opacity/content shape, long-press begin/change/end/cancel callbacks, reorder commit, drop haptic, debug output.
- `draggedCity`, lines 1642–1645; `beginReorderIfPossible`, 1647–1702.
- Coordinate/layout helpers: `convertGlobalFramesToContentSpace`, 1704–1713; `rectInContentSpace`, 1715–1718; `applyConvertedRowFramesIfNeeded`, 1720–1730; `scheduleRowFramesCommit`, 1732–1742; `rowFramesHash`, 1744–1755; `effectiveRowFramesForReorder`, 1757–1762.

The closure references and protocol witnesses are real internal connections, but they do not provide an external root. In particular, the timer does not acquire a running view subscription because no `CityListView` is created. Do not describe its removal as fixing an active timer leak or promise a runtime performance improvement.

### Controller/support inventory

`ReorderController` owns `isReordering`, `draggedCityID`, `sourceIndex`, `proposedIndex`, `dragInitialFrame`, `dragTranslationY`, the weak scroll reference, three KVO observations, scroll enablement state, and three log timestamps (1767–1781). Its attach, metrics, begin/update, destination calculation, auto-scroll, row-offset, commit, cancellation, reset, and observation methods are confined to this old path.

`attachedScrollView` (1783–1785) and `currentContentOffset()` (1832–1834) have no callers even inside the legacy path. They are already counted within the controller; do not count or remove them as an additional independent cleanup.

The old `onCancelled` callbacks and `ReorderController.cancel(reason:)` handle city-row reordering. They are unrelated to the recently corrected wheel drag cancellation.

### Shared dependencies that must not be removed

The legacy block uses shared production types, but their use by dead code does not make those types dead. Keep `City`, `CanonicalCity`, `CityCardView`, `AppTheme`, `SheetStyle`, the active UIKit cell/header classes, and all wheel views/models. For example, the active cell constructs `CityCardView` through `UIHostingConfiguration` at lines 1332–1344.

## 4. Other confirmed-unused declarations

These are separate optional commits, not prerequisites for removing the old list.

| File and range | Declaration | Reference analysis | Removable dependencies / estimate | Risk and confidence |
|---|---|---|---|---|
| [CityTimeFormatter.swift:65–68](/Users/srgmnk/Library/CloudStorage/Dropbox/Xcode/Timie/Hours/CityTimeFormatter.swift:65), [24–29](/Users/srgmnk/Library/CloudStorage/Dropbox/Xcode/Timie/Hours/CityTimeFormatter.swift:24) | `formatDetailsHeader(_:in:)`, `detailsHeaderDateFormatter` | The function name appears only at its declaration. Its private formatter appears only at the declaration and inside that function. No callback, protocol requirement, selector, or preview invokes it. | Remove the 4-line method and its exclusive 6-line formatter initializer: **10 lines**. Retain `formatTime`, `formatTimeComponents`, `formatDate`, and UTC-offset functions. | Low risk; high confidence. The static formatter is initialized only on access. |
| [TimeDialView.swift:225–228](/Users/srgmnk/Library/CloudStorage/Dropbox/Xcode/Timie/Hours/TimeDialView.swift:225) | `tickIndex(for:centerTickIndex:)` | No invocation or function-value reference. Other occurrences of `tickIndex` are the parameter/local uses of the active `relativeStep(from:to:)`, not calls to this helper. | **4 lines**; no dependencies can be removed with it. | Low risk; high confidence. Keep separate from the list cleanup and do not touch nearby gesture or drawing code. |
| [AppTheme.swift:31–32](/Users/srgmnk/Library/CloudStorage/Dropbox/Xcode/Timie/Hours/AppTheme.swift:31), [54–55](/Users/srgmnk/Library/CloudStorage/Dropbox/Xcode/Timie/Hours/AppTheme.swift:54), [90–91](/Users/srgmnk/Library/CloudStorage/Dropbox/Xcode/Timie/Hours/AppTheme.swift:90) | `glassFill`, `glassBorder` | Only declarations and light/dark initializer arguments occur in the project. No property reads, key paths, reflection, serialization, or view consumer found. `AppTheme` itself remains active. | Two fields and four constructor arguments: **6 lines**. | Low risk; high confidence. Remove only these unused fields/arguments; leave all theme values actually used by glass controls intact. |

## 5. Probably unused, active-but-redundant, and compatibility candidates

These are **not included** in the 1,117-line confirmed-removal total.

### A. Active dial-height measurement — defer

Locations: [TimeDialScreen.swift:31](/Users/srgmnk/Library/CloudStorage/Dropbox/Xcode/Timie/Hours/TimeDialScreen.swift:31), 138–144, 153–156, and 509–515; **19 lines** in total.

`dialHeight` is declared and assigned, but never read. The active list receives the fixed `cityListDesiredBottomGap` (47, 116), which eventually reaches UIKit's inset calculation (820–855). The comment claiming the measurement feeds list padding is stale.

Nevertheless, the background `GeometryReader`, preference emission/reduction, `onPreferenceChange`, and `@State` assignment are attached to the **active** screen. Their output is unused, but removing them changes the live dependency graph. Given the earlier iOS 27 propagation failure, strict equivalence requires a separate physical-device comparison. Classification: **probably removable, but active update/layout plumbing requiring verification**, not unreachable code.

Do not remove or change the outer `GeometryReader`, `TimeDialObservedContent`, `.id(...)`, safe-area logic, or active lifecycle callbacks while evaluating this candidate.

### B. Flow-layout-only delegate callbacks — verify framework dispatch

Locations: [TimeDialScreen.swift:1190–1216](/Users/srgmnk/Library/CloudStorage/Dropbox/Xcode/Timie/Hours/TimeDialScreen.swift:1190): `collectionView(_:layout:sizeForItemAt:)`, `collectionView(_:layout:minimumLineSpacingForSectionAt:)`, and `collectionView(_:layout:referenceSizeForHeaderInSection:)`.

The controller creates a `UICollectionViewCompositionalLayout` at 643–662 and supplies it at 664. No assignment of a flow layout was found. These three methods belong to the flow-layout delegate surface and appear obsolete for this layout.

However, they are Objective-C optional protocol callbacks on a registered delegate, not ordinary Swift functions requiring explicit call sites. Classification: **probably unused for this configuration; runtime verification required before removal**. Proposed verification: symbolic/source breakpoints or Instruments call evidence while testing list loading, resizing, appearance, compact/basic cards, headers, scrolling, and reordering. If confirmed, remove only the three callbacks (25 declaration lines, or 27 including separators) in a separate change. Any optional switch from `UICollectionViewDelegateFlowLayout` to `UICollectionViewDelegate` belongs in that same narrowly reviewed change, not the legacy block deletion.

Preserve the data-source methods, selection callbacks, supplementary-view method (1218–1242), compositional layout, and header/cell implementations.

### C. Discarded tick-width plumbing — not part of dead-list cleanup

[TimeDialView.swift](/Users/srgmnk/Library/CloudStorage/Dropbox/Xcode/Timie/Hours/TimeDialView.swift:47): constants at 47–48, arguments at 62–63 and 83–84, parameters at 277–278, discarded expression at 298. The path uses `lineWidth` at 299 instead.

This is redundant computation/parameter plumbing in the **active drawing path**, not an unused drawing function. Approximately 9 lines could be removed by a separately scoped signature cleanup, but it is unnecessary for the requested obsolete-list removal. Preserve `lineWidth`, tick lengths, tick selection, and rendering behavior. Classification: **active but redundant; defer**.

### D. Compatibility aliases — retain in this cleanup

- [City.swift:232–241](/Users/srgmnk/Library/CloudStorage/Dropbox/Xcode/Timie/Hours/City.swift:232): `init(name:timeZoneID:customName:)` and the `customName` computed alias have no current call sites, but both are explicitly documented as backward-compatible aliases. Classification: **intentionally retained compatibility code**. They are not JSON migration logic; that does not authorize removing their stated source-compatibility role.
- [EmptyStateQuote.swift:3](/Users/srgmnk/Library/CloudStorage/Dropbox/Xcode/Timie/Hours/EmptyStateQuote.swift:3): the `EmptyStateQuote = Quote` alias has no consumers. It appears to be a compatibility shim, but its intent is not explicitly documented. Classification: **probably unused, retain until that intent is resolved**. This does not make `Quote`, `EmptyStateQuoteProvider`, or `MainEmptyStateQuoteView` unused.
- [TimeDialScreen.swift:3](/Users/srgmnk/Library/CloudStorage/Dropbox/Xcode/Timie/Hours/TimeDialScreen.swift:3): `import Combine` may become redundant once the legacy Combine/KVO helper group is gone, but module imports are not meaningfully audited by a symbol-name search. Keep it in the first deletion and let an isolated compile check decide later; estimated optional saving is one line.

## 6. Active code and recent corrections that must be preserved

| Protected behavior | Current evidence | Removal boundary |
|---|---|---|
| iOS 27 direct model observation | `@StateObject viewModel` at TimeDialScreen:23; child constructed at 77; `TimeDialObservedContent` at 478–507 owns `@ObservedObject` and reads model inputs in its body. | Keep all these lines, the closure boundary, and `GeometryReader` at 71. The old list begins much later, at 1369. |
| Existing view identity/layout | Inner `.id` at 124; outer `.id` at 182; active overlay geometry and safe-area handling at 327–375. | No identity, modifier-order, animation, or layout edits in the legacy removal. |
| Wheel cancellation | TimeDialView:23, 99–181, 184–193; screen callbacks at 342–359 and cancellation/reset at 378–391; model cancellation at 77–82. | Preserve. These are distinct from old row long-press cancellation. |
| Inertia cancellation | TimeDialViewModel:122–157, especially the guard before snapping at 154. | No model edits. |
| Persistence protection and alerts | CityStore's status/load/save/migration/widget logic; screen status/sheet state at 6–39, alert lifecycle at 184–284. | No store edits; preserve sheet-dismissal ordering, acknowledgement, scene/onboarding checks, and alert modifiers. |
| UIKit list and callbacks | TimeDialScreen:547–1243; bridge coordinator publishes the binding at 565–568; active layout/registration at 643–724; `apply` at 739–814. | Preserve this whole active group in the first removal. |
| Active UIKit reordering | `handleLongPress` at 946, `finishInteractiveMovement` at 987, pending state application at 1018, reorder delegate at 1118–1143. | Do not confuse it with `ReorderController` at 1766. |
| Active header/cards | `CityListLogoHeaderView` at 1252–1301; `CityListReorderCollectionCell` at 1303–1367; SwiftUI card hosted at 1332. | End any kept prefix after the complete cell class. Preserve its lift animation and reuse cleanup. |
| Current-location card marker | `currentLocationMatchIndex` at 894–936 calls `City.isZeroOffsetReferenceCity`; that extension is at 1245–1250. | The extension is active and is not part of the old list. |
| Empty screen and shake | Empty branch at 83–106; `changeQuote` at 467; `ShakeDetectorView` / `ShakeDetector` at 517–545. | Preserve. UIKit motion and responder callbacks are indirect but active. |
| Existing active diagnostics | `log` at 431–435; `[DIAL]` calls at 173, 347, 355; bottom-inset probe at 623 and 845–854; UIKit reorder logs at 995 and 1135. | Preserve. Never remove logs by broad `[SCROLLPROBE]` or `REORDER` text matching. |
| MainActor corrections | ParallaxMotionManager:27–37 and 61; CityDetailsView:619–625. | Neither file needs changes. |
| Search cancellation and presentation IDs | CitySearchProvider completer/request checks; AddCitySheetView.DisplayResult at 40–64 and asynchronous search guards. | Neither is dependent on the old list. Preserve all current code. |
| Geographical evidence retention | CitySearchItem.GeographicalEvidence and evidence mapping in CitySearchProvider. | Intentionally retained evidence may lack current matching consumers; it is not dead code under the requested behavior. Preserve. |
| Current Location matching | CitySearchProvider:265–298; CurrentLocationCityProvider:105–119. | Preserve alias/name checks and reverse-geocoded fallback. |
| Widget functionality | Separate HoursWidget target; bundle constructs HoursWidget; AppIntent.swift reads shared records and supports widget selection. | No widget, App Group, JSON, UserDefaults, or privacy-manifest changes. |

The legacy view's `cities` binding cannot mutate CityStore because the view is never constructed. The active bridge's binding and `Coordinator.publishCities` remain the production route for deletion/reordering. Removing the old block does not remove that persistence path.

## 7. Smallest safe removal sequence

All steps below are **proposals for separately authorized implementation**. This audit does not execute them.

1. **Commit 1 — TimeDialScreen.swift only: remove the entire orphaned list group, current lines 1369–2465.** Treat it as one related dependency group: root view plus exclusively owned support. Keep lines 1–1367 byte-for-byte unchanged, including `TimeDialObservedContent`, the measurement pipeline, active UIKit types, and all active diagnostics. Do not remove imports or flow-layout delegates in this commit. Removing helpers before their legacy callers would create avoidable compilation failures.
2. **Build Debug and Release, then perform the primary screen regression checks below.** Review the diff as deletion-only. If anything fails, revert this one commit; do not compensate with active-code changes.
3. **Optional Commit 2 — CityTimeFormatter.swift only:** remove the unused details-header method and its exclusive formatter. Build both configurations and spot-check city/details formatting.
4. **Optional Commit 3 — TimeDialView.swift only:** remove the uncalled four-line `tickIndex` helper. Build both configurations; verify the diff contains no gesture, cancellation, animation, or active drawing changes.
5. **Optional Commit 4 — AppTheme.swift only:** remove the two unread theme fields and their light/dark arguments. Build both configurations; compare light/dark controls and pills.
6. **Defer all section 5 candidates.** Measurement removal, indirect delegate removal, active drawing signature cleanup, and compatibility alias decisions each need their own evidence and scope. Do not bundle them with confirmed dead-code removal.

If smaller commits within the first group are preferred, remove `CityListView` first while leaving its now-unreferenced helpers, build, then remove the controller and helper closure as a second commit. The single related-group deletion is simpler and avoids a deliberately incomplete intermediate cleanup.

## 8. Regression risks

- **Wrong deletion boundary:** deleting the active collection cell ending at 1367 or the `City` extension at 1245–1250 would break production behavior. Use declarations and the reviewed diff, not stale audit line numbers.
- **Similar names:** legacy `ReorderController` and UIKit `CityListReorderViewController` are different types. Old row gesture cleanup and wheel cancellation are different paths.
- **Indirect framework calls:** delegate methods, lifecycle overrides, selector handlers, preference reducers, and `View.body` cannot be labeled dead solely from direct-call counts. The legacy group is removable because its construction root is absent; active owners still retain their callbacks.
- **Active graph changes:** the dial-height output is unused, but removing its live measurement machinery deserves physical iPhone testing given the previous iOS 27 failure. It is intentionally excluded.
- **Overbroad cleanup:** matching log prefixes, deleting shared dependencies, changing imports, or “simplifying” the observed-content wrapper would turn a safe deletion into a behavioral change.
- **Evidence limits:** static source reachability supports high confidence for the closed legacy group, but no runtime performance benefit, binary-size saving, or post-removal device behavior has been measured. The count is source lines, not executed work.

## 9. Validation checklist for a future removal

### Source and builds

- [ ] Recheck references immediately before removal; working-tree line numbers can shift.
- [ ] Commit only the approved related group; preserve unrelated uncommitted changes.
- [ ] Confirm no app/widget/preview/resource reference to any removed type remains.
- [ ] Confirm the active prefix and every protected file are unchanged.
- [ ] Build the Hours scheme in Debug and Release, including HoursWidgetExtension.
- [ ] Check compiler errors/warnings and `git diff --check`.
- [ ] Confirm target membership, privacy manifests, persisted schemas, and App Group configuration are unchanged.

### Physical iPhone and presentation

- [ ] Cold-launch on the affected iOS 27 device; immediately rotate the wheel. Both wheel and city times must update without opening Add City.
- [ ] Repeat drags, inertia completion, new drag during inertia, reset during inertia, and reset during a drag.
- [ ] Interrupt a drag using backgrounding/Control Center; verify the next drag works without stale state.
- [ ] Open/dismiss Settings and Add City, then drag again.
- [ ] Test empty list, first addition, deleting a middle city, deleting the final city, and re-adding.
- [ ] Reorder UIKit cards by long press, cancel/release, scroll, tap a card, and confirm no duplicate lifecycle/haptic behavior.
- [ ] Test compact/basic cards, logo/header spacing, bottom gap, light/dark appearance, rename, and city details.
- [ ] Verify empty-state quote presentation and shake behavior.

### Persistence, search, and widgets

- [ ] Use isolated fixtures to check add/delete/reorder persistence and one alert per unresolved primary failure episode, including deferred presentation after sheets.
- [ ] Re-run existing search cancellation, row identity, geographical evidence, and Current Location tests; no algorithms should have changed.
- [ ] Confirm normal catalog IDs, reverse-geocoded unknown city names, selection, and already-added behavior remain unchanged.
- [ ] Confirm the widget reads the same committed city records and respects ordering/custom names.

## 10. Audit snapshot and reproducibility

`TimeDialScreen.swift` at audit time: 2,465 lines. SHA-256:

```text
8314b9856b1b507013ae21d8b14d87262920296c390fba3ecbeb8be8b4e13b4e
```

Representative project-wide search patterns used:

```sh
rg -n --hidden -g '!.git/**' -g '!docs/**' '\b(CityListView|ReorderController|CityRowFramePreferenceKey|ScrollViewIntrospector|ScrollIntrospectionView|ScrollViewHolder|RowLongPressDriverModifier|RowLongPressDriverView|RowLongPressDriverUIView|HitTestProbeView|HitTestProbeUIView|ENABLE_SCROLL_PROBE|ENABLE_CITYLIST_DEBUG|DISABLE_REORDER|cityListDebugLog)\b' .
rg -n --hidden -g '!.git/**' -g '!docs/**' '\b(dialHeight|DialOverlayHeightPreferenceKey|formatDetailsHeader|detailsHeaderDateFormatter|glassFill|glassBorder|tickIndex|EmptyStateQuote|customName)\b' .
rg -n 'NSClassFromString|NSSelectorFromString|Selector\(|_typeByName|Mirror\(|classNamed|NSKeyedUnarchiver|customClass|#Preview|PreviewProvider|#if|#selector' Hours HoursWidget Hours.xcodeproj LaunchScreen.storyboard
```

A temporary machine-readable reference inventory and file-hash snapshot were retained outside the production target at `/private/tmp/Hours-Dead-Code-Audit-kltapg_l/`. The audit report is the only repository addition; existing application, widget, configuration, and prior report files were not modified.
