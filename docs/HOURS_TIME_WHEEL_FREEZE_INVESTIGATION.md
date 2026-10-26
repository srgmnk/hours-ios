# Hours time wheel freeze investigation

Date: 2026-10-25  
Scope: Active time wheel, observable state propagation, and city time updates.  
Status: Read-only investigation; no corrective changes implemented. Existing DEBUG diagnostics remain in place.

This report records the latest investigation findings following reproduction on a physical iPhone running a Debug build. It supplements [HOURS_COMPREHENSIVE_CODE_AUDIT.md](HOURS_COMPREHENSIVE_CODE_AUDIT.md). Line references reflect the source with the existing DEBUG instrumentation.

## Executive finding

**The screenshots confirm stale values in the wheel’s gesture closure while the screen reads updated values from the same model.** This is stronger evidence for a screen-content update failure than for gesture interception. The exact invalidation failure is not yet proven.

The user confirmed that both the wheel and city times remain frozen after releasing the finger, and opening and closing Settings does not restore functionality in this reproduction.

The decisive sequence in screenshot 2 is:

| Event | Observed state |
|---|---|
| Settings dismissed | Model `1F25C095`: rotation `-33.75`, step `27` |
| Gesture 10 starts | Wheel `2C8D03CD`: `rotationInput=0.0`, step `0` |
| `model.dragBegin` | Same model still reports rotation `-33.75`, step `27` |
| `gesture.baseline` | Copies `startRotation=0.0` |
| First `model.dragApplied` | Writes rotation `0.0`, step `0` back into the model |

The mismatch survives across gestures and Settings dismissal. It is not simply a one-frame delay.

## 1. Why `isInteracting` immediately becomes false

Every assignment is in [TimeDialViewModel.swift](../Hours/TimeDialViewModel.swift):

| Location | Assignment | Purpose |
|---|---|---|
| Line 23 | Initial `false` | Initial state |
| Lines 80–83 | `true` | Capture `baseTime = now` when interaction begins |
| Line 111 | `false` | Normal drag completion |
| Line 124 | `false` | Explicit reset |
| Lines 135–136 | `false` when `deltaMinutes == 0` | Return to live-now calculation |

The first callback initializes the angle baseline, so its angular difference is zero. It then applies `startRotationDegrees`.

For gesture 1, zero is a valid starting rotation. For gesture 10, **zero is stale**, as the model already holds `-33.75`.

Applying zero synchronously produces:

```text
rotationDegrees = 0
→ dialSteps = 0
→ deltaMinutes = 0
→ isInteracting = false
→ selectedInstant = now
```

That fully explains the observed transition without invoking cancellation or inertia.

This is deterministic behavior in the existing implementation. It also means `isInteracting` does **not reliably represent whether a finger is dragging**: the screen’s separate session flag remains true. Whether returning to live-now while holding at zero is intended UX needs clarification, but this flag inconsistency does not explain frozen nonzero updates.

## 2. Complete rotation and time propagation

The shared owner is the single `@StateObject` at [TimeDialScreen.swift](../Hours/TimeDialScreen.swift), line 15.

```text
Wheel drag
→ screen.onDragChanged
→ viewModel.updateDialRotation
→ applyRotation
    ├─ @Published rotationDegrees
    └─ @Published dialSteps
         → deltaMinutes
         → selectedInstant
→ SwiftUI updates screen content
    ├─ TimeDialView(rotationDegrees, stepIndex)
    │    → Canvas → tickPath
    └─ CityListReorderUIKitView(selectedInstant)
         → updateUIViewController → controller.apply
         → reconfigureVisibleCells → UIHostingConfiguration
         → CityCardView → formatted time
```

The relevant rendering connections are:

- [TimeDialScreen.swift](../Hours/TimeDialScreen.swift), lines 262–268, passes model rotation and steps directly into the wheel.
- [TimeDialView.swift](../Hours/TimeDialView.swift), line 43 onward, draws using those input values. Line 296 adds `rotationDegrees` directly to each tick’s angle. There is no separate stored rendering rotation.
- [TimeDialScreen.swift](../Hours/TimeDialScreen.swift), lines 95–97, passes `selectedInstant` into the UIKit bridge.
- [TimeDialScreen.swift](../Hours/TimeDialScreen.swift), line 510 onward, forwards updated inputs to the controller; lines 724 and 784 refresh visible cells.
- [TimeDialScreen.swift](../Hours/TimeDialScreen.swift), line 1243 onward, creates the hosting configuration using that date.
- [CityCardView.swift](../Hours/CityCardView.swift), lines 20–21, formats the supplied date without storing an independent time snapshot.

Neither rendering branch checks `isInteracting`.

The model uses standard `@Published` properties and has no custom `objectWillChange` implementation. Those properties should publish changes through the synthesized publisher. Publishing occurs before assignment, but that normal ordering cannot explain inputs remaining zero across separate gestures. See [Apple: ObservableObject](https://developer.apple.com/documentation/combine/observableobject) and [Apple: Published](https://developer.apple.com/documentation/combine/published).

## 3. Derived state and competing writes

At [TimeDialViewModel.swift](../Hours/TimeDialViewModel.swift), lines 129–155:

- `dialSteps` is the rotation converted to five-minute increments.
- `deltaMinutes` includes the adjustment needed to round `baseTime`.
- For nonzero steps, `selectedInstant` uses rounded `baseTime` plus the step offset—even when `isInteracting` is false.
- `now` ticks every second. It does not reset rotation or steps.
- `baseTime` changes on interaction initialization or explicit reset, not on every drag update.

Consequently, the earlier logged rotations around `-28.969` and `-17.187` correspond to steps `23` and `14`. With the same anchor, the selected dates should differ by **45 minutes**. The false interaction flag cannot hold both at the original time.

Other paths do not explain the complete captured failure:

- **Inertia:** the initial drag starts with no inertia handle. Cancelled tasks can still snap—an existing defect—but cannot explain stale zero inputs before that first task starts.
- **Animations:** drag updates have no explicit animation wrapper. Reset and inertia snapping use springs; there is no animation-based gate suppressing both branches.
- **UIKit reordering:** `apply` defers card updates while `isReordering` is true, but that cannot independently freeze the SwiftUI wheel.
- **Identity:** the screenshots show the same model identifier in screen and drag logs. A simple “callbacks update a different model” explanation is therefore substantially weakened.

## 4. Confirmed defect and most likely shared failure point

### Confirmed: stale gesture inputs overwrite newer model state

**Confidence: High.** The installed gesture uses stale rotation/step inputs. Its baseline initialization then overwrites a newer model rotation with stale zero. The assignment responsible is at [TimeDialView.swift](../Hours/TimeDialView.swift), lines 128–130.

This explains the reset to zero at the beginning of gesture 10. It does not yet establish why the inputs became stale.

### Leading hypothesis: shared screen content is not refreshing

**Confidence: Medium.** The content supplying both displays is not refreshing correctly across the **model observation → screen/`GeometryReader` content → child input** boundary.

Both branches are constructed inside the same `GeometryReader` at [TimeDialScreen.swift](../Hours/TimeDialScreen.swift), line 59. Meanwhile, outer `screen.context` handlers execute and read current model values. Thus “the entire SwiftUI screen is no longer executing” is too broad.

There remains an important distinction: the logs prove stale values in gesture closures, not directly in the current Canvas drawing closure. The reported frozen wheel and cards strongly support stale displayed content, but a retained gesture closure alone would not explain both displays.

The constraint warning, gesture-gate timeout and “cannot add handler” messages lack enough context to identify a cause. Delivered callbacks show that gesture-gate failure is not preventing this recorded drag from reaching the model.

## 5. Smallest next diagnostic step

Use debugger breakpoints in the existing Debug build; no source changes are necessary.

Start at **`dialOverlay(in:)`, line 264 of [TimeDialScreen.swift](../Hours/TimeDialScreen.swift)**, during a frozen drag. Check whether it executes again and, if so, inspect the model identity, rotation, steps and `selectedInstant`.

| Result | Next conclusion/check |
|---|---|
| Model updates, but `dialOverlay` is not reevaluated | Localizes the failure upstream of child construction. Compare hits in the screen body and `GeometryReader` content. |
| `dialOverlay` receives current values | Check `TimeDialView.body` and its Canvas closure for the values actually received. |
| Wheel body/Canvas values advance | Stale gesture capture and visual presentation must be investigated separately. |
| UIKit `updateUIViewController` receives stale dates or never runs | Supports the shared content-update hypothesis. |
| UIKit receives changing dates | Check `apply`’s reorder guard and cell configuration; the card failure is further downstream. |

First inspect `selectedInstant` **after** `applyRotation` completes to confirm its runtime value, since the existing model log omits it.

Avoid adding a new model read at the top of the screen body as the first experiment: that could change dependency tracking and conceal the failure. The next goal is to locate the first boundary that stops advancing, before choosing a fix.

## Change status

This report is the only file added for the Markdown export. No Swift source, gesture priorities, hit testing, layout, animations, architecture, or UX were changed during the read-only investigation or this export. The earlier DEBUG instrumentation remains unchanged.
