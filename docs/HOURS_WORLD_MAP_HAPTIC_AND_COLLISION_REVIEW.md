# Hours World Map: Haptic Correction and Collision Review

Date: 2026-10-26

Status: Haptic implemented and validated. Collision handling proposed only.

## Implemented haptic

Only the switcher action in `Hours/TimeDialScreen.swift` changed: four lines were added around the existing presentation assignment.

```swift
let previousPresentation = presentation
presentation = presentation == .list ? .map : .list
guard presentation != previousPresentation else { return }
let generator = UIImpactFeedbackGenerator(style: .medium)
generator.impactOccurred()
```

This follows the existing Add/Settings convention: one medium impact request after a successful state change. Initial rendering, rejected changes, and unrelated updates produce no switch feedback. Appearance, layout, animations, gesture priority, observation, and wheel behavior remain unchanged. Physical playback is system-controlled: [Apple API documentation](https://developer.apple.com/documentation/uikit/uiimpactfeedbackgenerator/impactoccurred%28%29).

### Verified results

- Debug and Release builds passed, including `HoursWidgetExtension`, with zero warnings.
- Eight relevant simulator tests passed: two impact-count tests, one switching/map-gesture test, and five live-state regressions.
- Instrumented iPhone 18 Pro simulator: exactly one impact call per successful switch; zero at launch, for rejected binding changes, and during unrelated wheel, map-scroll, or city updates.
- Existing regressions passed: search 129 checks; persistence 39 assertions; resolver 864 checks; coordinate propagation/compatibility 577 checks.
- `git diff --check` passed. Physical-device haptic feedback was not tested.

## Current marker architecture — verified

Inspected `WorldMapView.swift`, `WorldMapObservedContent.swift`, `CityTimeFormatter.swift`, and `LegacyCityCoordinateResolver.swift`; none changed.

- The existing resolver supplies coordinates; standard Web Mercator projects them into a square canvas.
- Image and markers share the canvas, origin, uniform scale, and native horizontal scroll offset.
- Each marker currently combines a geographic dot and two centered labels in one view.
- Reference dimensions: 56-point marker height, 14-point city text, 18-point time text, two 20-point label rows. Width uses measured attributed strings, a 57-point minimum, and two points of allowance.
- Labels begin four points below the dot. Fonts currently use fixed sizes rather than Dynamic Type.
- Names use `City.displayName`. Times use `CityTimeFormatter.formatTime` with the supplied `selectedInstant`, clock preference, and meridiem.
- Time changes update existing marker views. Horizontal scrolling translates the canvas without reformatting or rearranging labels.

## Recommended collision approach — not implemented

Calculate in **rendered canvas points after scaling**, using actual label bounds and outline allowance. Exclude transparent marker-image padding from collision bounds.

1. Preserve every projected dot.
2. Measure individual and potential shared labels.
3. Detect overlapping default label rectangles.
4. Group eligible nearby labels with identical displayed time strings.
5. Try remaining labels in a fixed order: below, above, left, right. Derive spacing from existing dot radius and four-point gap; avoid covering other dots.
6. If all candidates collide, choose the least-overlapping candidate with deterministic tie-breaking. Preserve labels and dots.

Use saved-city order for priority and name order, with existing IDs resolving ties. Avoid random or history-dependent placement.

### Equal displayed times

Require overlapping label bounds **and** a compact rendered-dot footprint. Compare complete formatter output, never time-zone IDs. Do not use unrestricted connected components: overlap chains can join distant endpoints.

Follow the supplied New Delhi/Ghaziabad reference: keep both dots and center one shared label below their combined dot bounds.

- Show up to two full display names when they fit.
- Append `+N` for members whose names are omitted.
- Reserve suffix space before truncating at character boundaries with an ellipsis.
- Preserve each city's full name/time for accessibility.

### Different displayed times and dense groups

Keep separate labels and times. The Bangkok/Hong Kong reference illustrates below/above placement. Never move dots to resolve text collisions. When space is insufficient, retain a deterministic least-overlap result without discarding cities or replacing dots with a cluster.

## Stability, boundaries, and performance

Cache placement by cities/display names, projected anchors, viewport dimensions, map scale, font metrics, measured label bounds, and equal-time group membership.

- City, viewport, scale, font, or relevant text/group changes invalidate the plan.
- Selected-time updates refresh text and check the signature; reuse placement when dimensions and grouping remain unchanged.
- Exclude horizontal `contentOffset` from the key. Scrolling translates the established layout; restoration recreates the same layout for the same inputs.
- Constrain candidates at actual image boundaries and account for the fixed vertical crop.
- Allow normal horizontal viewport clipping during panning. Keeping every label inside the moving viewport would require moving labels relative to the map and conflict with stability.
- A simple pass has quadratic worst-case work, performed only when inputs change. Cache measurements and avoid an all-pairs matrix. Profile 152-city and 1,000-city fixtures before introducing a spatial index; impose no marker limit.
- Keep the existing mutable formatters on their current thread. Add no timer, gesture recognizer, or dependency.

## Proposed validation fixtures

Use isolated fixtures with existing registry coordinates or frozen, country/region-verified geographical records. Do not modify production coordinates, identities, or saved records.

| Fixture | Expected validation |
|---|---|
| Bangkok / Hong Kong | Different times; separate below/above labels matching the reference |
| New Delhi / Ghaziabad | Two dots; one shared name/time label |
| Saratov / Samara | Different zone IDs, identical displayed times; eligible local grouping |
| Saint Petersburg / Vyborg | Nearby grouping, long names, preserved dots |
| London / Cambridge | Group only when rendered bounds overlap |
| New York / Newark / Jersey City | Three-dot group; correct names and `+N` count |
| London / Dublin | Equal displayed times across different zones |
| London / Tokyo | Never group distant cities, including equal-time situations |
| London / Paris | Separate candidates for nearby different-time labels |
| Five or more overlapping markers | Deterministic fallback; no lost dots or labels |
| Long custom names | Width cap, suffix reservation, Unicode-safe truncation |
| SE / Pro / Pro Max viewports | Recalculate on resize; repeatable results |
| Horizontal pans and position restoration | Canvas label rectangles stay fixed; no scroll-frame layout passes |
| DST transitions | Correct text and group merging/splitting |

Transition instants verified with the existing formatter:

- London: `2026-03-29T01:00Z` and `2026-10-25T01:00Z`.
- New York: `2026-03-08T07:00Z` and `2026-11-01T06:00Z`.
- Mexicali / San Luis Río Colorado: nearby different-zone fixture whose displayed times change from different to equal at `2026-03-08T10:00Z`.

## Future scope and unresolved decisions

Prefer changes confined to `WorldMapView.swift`, separating per-city dots from independently positioned labels. A small pure layout helper is justified for testability. Keep observation, coordinate resolution, formatting, storage, search, widgets, and scrolling intact.

Decide and visually validate the label-width cap, compact-group threshold, unavoidable-overlap scoring, and wheel/blur occlusion policy. Dynamic Type adoption would be a separate appearance change.

Collision handling remains unimplemented. Existing uncommitted work, `.gitignore`, and Git exclusions were preserved. Nothing was staged, committed, or pushed.
