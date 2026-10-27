# Hours World Map — Stage 1 Audit

Audit date: 26 October 2026 (Asia/Bangkok)

Status: read-only investigation complete; feature implementation has not started.

## Scope and repository preservation

This audit assesses the existing map asset, coordinate projection, city data, time synchronization, main-screen integration, and Figma reference. It proposes small, independently testable implementation stages.

No production files, assets, persistence formats, or Figma nodes were changed during the audit. The two pre-existing staged worldmap files remained staged and unchanged. Nothing was staged, committed, or pushed. Existing UI, identifiers, search behavior, uncommitted changes, and `.gitignore` were preserved. Diagnostic artifacts and the regression runner's temporary files were created outside the repository.

This Markdown document was subsequently added at the user's request to consolidate the audit.

The feature can reuse the existing time model and screen structure. The principal unresolved issues are coordinate recovery for older saved cities, marker visibility within the fixed vertical crop, and the switcher's overlap with the wheel's gesture region.

Throughout this report:

- **Verified** means inspected in the current source, asset metadata, Figma node properties, or completed validation.
- **Assessment** means an inference from that evidence, with its limits stated.
- **Recommendation** describes future work; it has not been implemented.

## Approved product requirements

1. The existing city list remains the default presentation.
2. Map mode displays the watercolor world map.
3. A List/Map button switches between presentations.
4. The switcher is in the lower-left corner, above the time wheel.
5. The switcher reuses the visual style of Add and Settings.
6. The map scrolls horizontally only; vertical movement is disabled.
7. Horizontal scrolling stops at the image boundaries. Infinite wrapping is unnecessary.
8. All saved cities must be represented by markers, regardless of count.
9. Each marker displays its city name and local time.
10. Marker times follow the existing `selectedInstant`.
11. Switching presentations preserves selected time and wheel rotation.
12. Map interaction must not intercept wheel gestures.
13. The first map visit centers on the primary city when reliable coordinates exist.
14. Subsequent visits preserve the last horizontal map position.
15. An expanded iPhone Duo layout will eventually show list and map together, but is a separate future task.

The audit does not authorize implementation, asset changes, production UI changes, a wheel refactor, persistence migrations, identifier changes, search changes, new dependencies, or Git staging/commits/pushes.

## 1. Map asset findings

Asset configuration: [`Hours/Assets.xcassets/worldmap.imageset/Contents.json`](../Hours/Assets.xcassets/worldmap.imageset/Contents.json).

Image: [`Hours/Assets.xcassets/worldmap.imageset/map-l.jpg`](../Hours/Assets.xcassets/worldmap.imageset/map-l.jpg).

### Verified properties

| Property | Finding |
|---|---|
| Dimensions | 3000 × 3000 pixels |
| Aspect ratio | 1:1 image; equal horizontal/vertical resolution metadata |
| Format | Progressive JPEG, 8-bit RGB, three channels |
| File size | 3,987,335 bytes, approximately 3.80 MiB |
| Transparency | None |
| Orientation | EXIF orientation 1: upright and unrotated |
| Resolution metadata | 72 × 72 DPI; this does not determine SwiftUI display size |
| Asset configuration | Universal image; filename assigned only to the 3× slot; 1× and 2× slots empty |
| Appearance variants | No dark-mode or other appearance variant |
| Geographic metadata | No CRS or geographic registration information found |

### Color profile

`sips` reports `sRGB IEC61966-2.1`. However, inspection found no embedded ICC profile, and EXIF ColorSpace is `65535`, meaning uncalibrated.

Therefore, sRGB is the current decoded interpretation, not a verified embedded profile. Actual asset-catalog output and device appearance should be checked before treating color reproduction as settled.

### Memory and display scaling

A conventional four-byte decoded buffer would occupy approximately **34.3 MiB**, before textures, intermediate rendering surfaces, and framework overhead. Compressed file size is not runtime memory cost.

The 3× assignment implies a nominal 1000 × 1000-point image. Explicit display sizing should control the map. Figma displays the image at 1129 points square; on a 3× display that enlarges the source by approximately 12.9%.

### Margins and padding

The artwork reaches every edge. There is no obvious rectangular border, transparent padding, or constant-color margin. Pale polar areas are part of the artwork and must not automatically be trimmed.

**Assessment:** zero padding is the appropriate initial configuration, subject to the projection acceptance check below.

## 2. Projection accuracy assessment

The asset was compared against **5,128 coastline vertices** from Natural Earth, projected using the standard spherical Web Mercator formula. The comparison applied no fitted offsets and no independent horizontal/vertical scale adjustment.

Reference: [Natural Earth coastline dataset](https://www.naturalearthdata.com/downloads/110m-physical-vectors/110m-coastline/), using the [published GeoJSON](https://github.com/nvkelso/natural-earth-vector/blob/master/geojson/ne_110m_coastline.geojson).

### Verified visual comparison

The projected reference shows good broad alignment around:

- Greenland and Scandinavia.
- Western and southern Africa.
- India and Southeast Asia.
- Australia.
- South America.

There is no obvious systematic translation, rotation, or inset requiring correction. Antarctic boundaries differ visibly. This comparison does not establish whether those differences arise from coastline generalization, ice-boundary representation, or the artwork.

A diagnostic overlay was generated at `/private/tmp/hours-audit-projection-overlay.png`. It is a temporary local audit artifact, is not bundled with this document, and may be removed by the operating system. The source asset was not altered.

### Geographic extent

**Assessment:** the image is consistent with a complete square Web Mercator world covering:

| Parameter | Supported extent |
|---|---|
| Longitude | −180° to +180° |
| Latitude | Approximately −85.05112878° to +85.05112878° |
| Projection | Spherical Web Mercator / EPSG:3857 |
| Orientation | North up, west left |

This conclusion follows from geographic comparison, not merely the image's square dimensions.

### Calibration recommendation

Use the full image rectangle with zero padding as the initial projection configuration. No manual city adjustments are justified.

Exact export bounds and subpixel alignment remain unverified because the JPEG contains no geographic registration metadata. A higher-resolution landmark check should be an implementation acceptance gate. Do not invent calibration offsets before that check produces evidence for them.

## 3. Deterministic coordinate transformation

Use WGS84 longitude `λ` and latitude `φ`, in degrees:

```text
φmax = atan(sinh(π)) × 180 / π
     ≈ 85.0511287798066°

φc = clamp(φ, -φmax, +φmax)
φr = φc × π / 180

u = (λ + 180) / 360
v = (1 - asinh(tan(φr)) / π) / 2
```

This is the normalized form of the spherical equations documented by [PROJ](https://proj.org/en/stable/operations/projections/webmerc.html).

### Input validation and boundaries

- Reject nonfinite coordinates.
- Reject latitude outside ±90° and longitude outside ±180°.
- Clamp valid polar latitudes to the Mercator limit.
- Preserve `−180° → u=0` and `+180° → u=1`; do not wrap the right boundary to the left.
- Clamp final floating-point roundoff to `[0,1]`.

### Orientation and origin

```text
Northwest = (0, 0)
Equator / Greenwich = (0.5, 0.5)
Southeast = (1, 1)
```

For image dimensions `W × H` and verified padding `L, T, R, B`:

```text
xImage = L + u × (W - L - R)
yImage = T + v × (H - T - B)
```

For this asset, the evidence supports the initial values:

```text
W = H = 3000
L = T = R = B = 0
```

These are continuous image-edge coordinates. The origin is the upper-left outer edge; pixel centers are at `(i+0.5, j+0.5)`. Do not mix this convention with a `W−1` pixel-index formula.

### Display scaling and horizontal scrolling

For uniform display scale `s`, fixed vertical placement `Y`, horizontal placement `X`, and horizontal scroll offset `o`:

```text
xViewport = X + s × xImage - o
yViewport = Y + s × yImage

0 ≤ o ≤ max(0, s × W - viewportWidth)
```

When markers are children of the scrolling content, the scroll view applies `−o`. Marker code must not subtract it again.

Initial primary-city centering:

```text
oInitial = clamp(
    X + s × xPrimary - viewportWidth / 2,
    0,
    maximumOffset
)
```

For any subsequently verified geographic crop, normalize projected coordinates against that crop's projected bounds. Latitude must not be interpolated linearly. Calibration belongs to the image as a whole, never to individual cities.

## 4. Existing city-coordinate availability

### Model inventory

| Representation | Coordinates available? | Persistence |
|---|---|---|
| `CanonicalCity` / `City` | No | Saved city record |
| `CitySearchItem.GeographicalEvidence` | Optional latitude/longitude, place identifiers, and address evidence | Explicitly excluded from encoding |
| MapKit search results | Validated coordinates copied into geographical evidence | Lost when converted to `City` |
| Current-location provider | Receives device and reverse-geocoded locations | Does not attach coordinates to its resulting search item |
| Local catalog | No coordinates in any of its 152 records | Bundled JSON |
| Widget city record/entity | No coordinates | Separate shared snapshot |

Relevant sources:

- [`City.swift`](../Hours/City.swift)
- [`CitySearchItem.swift`](../Hours/CitySearchItem.swift)
- [`CitySearchProvider.swift`](../Hours/CitySearchProvider.swift)
- [`CitySearchDeduplicator.swift`](../Hours/CitySearchDeduplicator.swift)
- [`CurrentLocationCityProvider.swift`](../Hours/CurrentLocationCityProvider.swift)
- [`Resources/cities.json`](../Hours/Resources/cities.json)
- [`HoursWidget/AppIntent.swift`](../HoursWidget/AppIntent.swift)

### Where evidence is lost

`CitySearchItem.asCity` retains only canonical identity, name, and time-zone identifier. It discards coordinates, country fields, provider identifiers, and address context.

Current-location conversion loses coordinates earlier: it returns a catalog item or constructs an item without geographical evidence.

Search deduplication can retain and merge evidence during a search session. Its three reviewed catalog anchors—Bangkok, Moscow, and Paris—are matching evidence, not a complete coordinate catalog. They should not be expanded or repurposed by changing deduplication behavior.

### Local catalog

The bundled catalog contains 152 records with these fields:

```text
id
city
country
timeZoneIdentifier
aliases
```

The search provider decodes these as `CitySearchItem` values. It also provides coordinate-free fallback items, popular-city results, and UTC/GMT reference items.

### Serialization and legacy loading

[`CityStore.swift`](../Hours/CityStore.swift) encodes an ordered `[City]` array to Application Support `cities.json`, using atomic writes. Its synthesized shape contains:

```text
canonicalCity:
    id
    name
    timeZoneID
customDisplayName: optional
```

The existing loader already performs identity normalization after successful decoding:

- Existing `city:` identities, including `city:mapkit:` identities, are preserved.
- Older identities can resolve through the catalog or existing fallback rules.
- Custom UTC/GMT identifiers are normalized.
- Array ordering and custom display names are retained.

There is **no custom decoder supporting an older flat city schema** in the current `City` model. Its backward-compatible initializers are source-code aliases, not JSON migration support.

The widget snapshot preserves array order and canonical IDs and contains no geographical evidence. Its fields are `id`, `canonicalName`, optional `customDisplayName`, and `timeZoneIdentifier`. The app mirrors it to an app-group file and shared defaults; the widget reads the file first and then defaults. The widget's timeline remains independent of the screen's selected instant.

### Smallest safe future coordinate strategy

Use an independent coordinate registry keyed by the **existing `City.id`**:

1. Supply reviewed coordinates for catalog cities through a separate bundled lookup, leaving the search catalog and identifiers unchanged.
2. Capture valid search evidence at the existing selection boundary, before `asCity` discards it.
3. Resolve older records independently, accepting only sufficiently verified matches.
4. Represent unresolved, ambiguous, and nongeographic entries explicitly in resolver state.

Important limits:

- `city:mapkit:` identifiers are hashes; coordinates and provider identifiers cannot be recovered from them directly.
- A fresh provider result may permit an exact identity match, but changed metadata or unavailable network access can prevent recovery.
- Name plus time zone is insufficient for ambiguous legacy cities.
- A UTC/GMT offset is not a geographical location.
- A device location should not silently become the permanent city-center coordinate.
- The existing legacy identity-normalization heuristics should not be treated as proof of geographical equivalence.

**All existing records cannot be guaranteed a truthful marker from the stored information alone.** An unresolved-entry policy is necessary. Cross-launch retention of newly obtained coordinates would also require a separately approved cache/persistence decision. An in-memory registry preserves the current formats but cannot provide that durability.

## 5. Time synchronization architecture

### Existing source of truth

```text
TimeDialScreen
    @StateObject TimeDialViewModel
        selectedInstant
            ↓
    TimeDialObservedContent
            ↓
        city list / future map
```

[`TimeDialViewModel.swift`](../Hours/TimeDialViewModel.swift) owns `now`, `baseTime`, `dialSteps`, rotation, interaction state, inertia, and the existing one-second ticker. `selectedInstant` is recomputed from that state.

The map should receive `selectedInstant` directly from the existing `TimeDialObservedContent` closure in [`TimeDialScreen.swift`](../Hours/TimeDialScreen.swift).

Each marker should use:

```swift
CityTimeFormatter.formatTime(selectedInstant, in: city.timeZone)
```

This reuses the existing time-zone, DST, locale, and 12/24-hour formatting behavior in [`CityTimeFormatter.swift`](../Hours/CityTimeFormatter.swift).

### Integration constraints

No new timer, time model, date-offset calculation, or wheel instance is needed. Presentation changes must not call `resetToNow`, change `resetSignal`, or introduce presentation-dependent identity around the wheel or observed-content wrapper.

Projection and coordinate resolution should remain independent of time changes. Only marker text needs the selected instant.

Keep `TimeDialObservedContent` observing below the geometry boundary and invoking its builder with fresh model values. Do not replace it with a closure that captures a stale instant.

## 6. Recommended map component structure

### Minimal responsibilities

| Proposed component | Responsibility |
|---|---|
| `WorldMapProjection.swift` | Pure coordinate validation and projection |
| `CityCoordinateResolver.swift` | Coordinate lookup and explicit resolution states keyed by existing city IDs |
| `WorldMapView.swift` | Image geometry, marker layer, viewport, and scroll-state bindings |
| `CityMapMarkerView.swift` | City display name and formatted local time |
| Optional private scroll adapter | Strict boundary behavior using `UIScrollView` |

Use one uniformly scaled image and a marker overlay sharing its coordinate system. Anchor each marker's **dot center** at the projected point; the label extends below it. Do not center the entire label-and-dot stack on the coordinate.

Render every resolved saved city without a count limit. Stable city IDs should drive marker identity. Offscreen drawing can be optimized later without removing cities from the map model. Clustering and merging labels are not part of the approved requirements.

### Is native SwiftUI ScrollView sufficient?

For horizontal scrolling, fixed vertical geometry, finite content, and position observation/restoration: **yes**. The project's deployment target supports `ScrollPosition` and scroll-geometry observation.

For a strict boundary stop without rubber-band overscroll: **not through the public bounce options in the installed SDK**. They are `automatic`, `always`, and `basedOnSize`; the last still bounces when content exceeds the viewport. See Apple's [ScrollBounceBehavior documentation](https://developer.apple.com/documentation/swiftui/scrollbouncebehavior).

Given the literal requirement to stop at boundaries, recommend a small, local `UIScrollView` adapter with:

- `bounces = false`.
- Vertical content extent equal to the viewport.
- No vertical bounce.
- Explicit map content geometry and insets.
- Native pan recognition and deceleration.

This remains a system-component solution. It needs no custom drag physics, dependency, global appearance change, or MapKit renderer.

### Position ownership

Keep map position and initialization state at screen level, outside conditional map creation:

- Center on the first saved city only when reliable coordinates exist.
- Never override a position the user has already chosen.
- Do not recenter on every time update, mode change, or reorder.
- Restore the last offset on return.
- Preserve normalized center when viewport dimensions change, then clamp to bounds.

Screen-lifetime preservation is the minimal interpretation. Persistence across app termination remains unspecified.

### Rendering efficiency

- Keep the image's identity stable and avoid decoding it on time updates.
- Recompute normalized marker positions when coordinates change, not when time changes.
- Update marker labels from the existing selected instant.
- Do not repeatedly write a scroll offset during ordinary label updates.
- Avoid additional compositing or offscreen drawing layers unless measurement demonstrates a need.
- Keep hidden presentations noninteractive and inaccessible; profile any unnecessary hidden rendering before adding more architecture.

## 7. Main-screen integration points

The content insertion point is the existing content group near the start of [`TimeDialScreen.swift`](../Hours/TimeDialScreen.swift), inside `TimeDialObservedContent` and beneath the dial and controls.

### Recommended integration

- Add a separate List/Map presentation state, initially List.
- Keep `CityViewPreference.basic/compact` unchanged; it controls card layout.
- Preserve `CityListReorderUIKitView`, preferably with stable mounted identity when switching, to retain its UIKit state.
- Disable hit-testing and accessibility exposure for the inactive presentation.
- Keep the existing wheel, Now control, top controls, sheet modifiers, and observation wrapper outside presentation switching.
- Retain the list's existing logo header. Map mode needs its own noninteractive `HoursLogo` placement using the existing asset and layout constants.
- Reuse [`GlassSurfaceModifier`](../Hours/GlassSurfaceModifier.swift) with a capsule and the existing control typography for the switcher.
- Leave `TrailingRegionControls` and its iOS 27.1 reserved-region logic unchanged.

The existing outer identities depend on empty/list state and color scheme. Adding presentation mode to an identity encompassing the wheel or observation boundary would introduce unnecessary reconstruction and must be avoided.

The existing UIKit list retains reorder, swipe, rename, selection, and details behavior. It receives the same selected instant and derives primary-city behavior from the first saved city. It should remain the production list implementation.

### Gesture and hit-testing conflicts

[`TimeDialView.swift`](../Hours/TimeDialView.swift) uses a **512 × 512 rectangular content shape** and `DragGesture(minimumDistance: 0)`. Its interactive area is larger than the visible tick arc.

The map must be a sibling beneath the wheel, never an ancestor scroll container around it. Map interaction must exclude the wheel's existing region, including transparent portions. Decorative map content can extend underneath without becoming an additional gesture target.

The Figma switcher occupies part of that wheel rectangle. Consequently, exact Figma placement and preserving every point of the wheel's existing gesture region are incompatible. The implementation should follow the approved "above the wheel" requirement, with final placement resolved before integration.

Keep the existing Add, Settings, rename, and city-details sheets on their current parent. Preserve the existing bottom dead zone, drag cancellation, inertia, and Now reset behavior.

The existing [`ProgressiveBottomBlurOverlay`](../Hours/ProgressiveBottomBlurOverlay.swift) is already noninteractive. Its current production behavior should be retained rather than changed merely to match Figma's different static blur measurement.

## 8. Figma design findings

The supplied [Figma frame](https://www.figma.com/design/YH7MouHlewHKjKVJDtCKXh/Hours-iOS?node-id=570-5423) was accessible. The screenshot, child design contexts, and read-only node properties were inspected.

### Verified geometry

| Element | Measurement |
|---|---|
| Screen frame | 393 × 852 |
| Map layer | 1129 × 1129 at `x = −634`, `y = −13` |
| Figma image source | 3000 × 3000, unrotated image fill |
| Add control | 87 × 48 at `(20,60)` |
| Settings control | 48 × 48 at `(325,60)` |
| List switcher | 72 × 48 at screen-relative `(24,780)` |
| Bottom progressive blur | 393 × 160, starting at `y = 692`; radius progresses 0 → 24 |
| Wheel bounds | Approximately `x = −60`, `y = 722`, size 512 × 512 |

The switcher's coordinates were obtained from its absolute transform. Its ancestors are rotated, so adding local positions would produce an incorrect result.

### Verified marker appearance

- Dot: 12-point diameter, `#FF4000`.
- White outside stroke: 2 points.
- Shadow: black at 20%, radius 8, vertical offset 4.
- Gap before text: 4 points.
- Name: SF Pro Semibold, 14 points, 20-point line height, −4% tracking.
- Time: SF Pro Semibold, 18 points, 20-point line height, −4% tracking.
- Text: black with a 1-point white outside stroke.
- Bangkok marker frame: 57 × 56.

### Verified switcher appearance

- SF Pro Medium, 16 points, 20-point line height, −4% tracking.
- White fill at 20% plus the same Figma glass effect as Add and Settings.
- Rounded pill appearance.

The existing app's system glass modifier is the appropriate implementation reuse point; Figma's internal glass parameters are not a reason to rebuild that style.

### Crop, wheel relationship, and safe areas

The artwork extends behind the status area, controls, and wheel. The static frame establishes this composition but does **not** establish responsive safe-area behavior across devices.

The Figma map crop corresponds approximately to latitude **+84.68° through −68.73°** under the validated projection. Some visible southern locations also fall within the blur/wheel area.

The reference includes "New Delhi, Ghaziabad +1," suggesting grouped presentation. That is not authorization to implement clustering; it conflicts with the approved individual-marker requirement.

Figma's markers are visual references, not geographic calibration anchors. Their positions must not override deterministic projection from reliable coordinates.

## 9. Risks and unresolved questions

| Issue | Consequence / recommended handling |
|---|---|
| Missing or ambiguous legacy coordinates | Do not guess. Define how unresolved saved entries are represented before claiming complete coverage. |
| UTC/GMT reference entries | They have no truthful point location and require an explicit product policy. |
| Fixed vertical crop | Some coordinates become unreachable through horizontal scrolling alone. Validate full-height fitting or another approved deterministic framing rule. |
| Switcher overlaps wheel hit region | Resolve placement while preserving the existing wheel rectangle. |
| Dense or coincident cities | Individual labels can overlap. Keep geographic anchors exact; do not silently cluster or move cities. |
| Map-position lifetime | Preserve across mode switches initially; cross-launch restoration is not yet specified. |
| Coordinate durability | In-memory evidence disappears on relaunch; separately approve any future durable cache without changing existing saved-city formats. |
| Dark mode and large text | Only this light reference was inspected; marker contrast and layout need validation. |
| Large decoded image | Profile memory and switching on devices; avoid repeated image decoding and unnecessary offscreen composites. |
| Missing embedded ICC profile | Verify actual asset-catalog output and device appearance before treating color reproduction as settled. |
| Exact geographic registration | Broad coastline alignment supports the expected extent, but export bounds and subpixel accuracy remain unverified. |

The smallest coverage-safe framing is to fit the full projected height within the usable marker viewport. It would look less enlarged than Figma. That tradeoff needs resolution: copying the crop cannot guarantee visibility for arbitrary saved cities.

No additional interface elements, unresolved-city treatment, clustering behavior, or persistence scheme are approved by this audit.

## 10. Minimal implementation sequence

All component filenames below are proposed future changes. None of these feature files were created during the audit.

Each stage should remain independently testable and reversible. Keep production integration until the standalone behavior is proven.

| Stage | Files requiring changes | Expected behavior and validation criteria | Main risks and dependencies |
|---|---|---|---|
| **1. Asset and projection validation** | New `WorldMapProjection.swift`; projection tests/fixtures | Verify origin, polar clamping, ±180°, invalid values, padding convention, and coastline alignment. Keep the asset unchanged. | Establish geographic bounds and acceptable visual tolerance first. |
| **2. Standalone scrolling map** | New `WorldMapView.swift`; private scroll adapter if required | Display the image alone. Verify aspect ratio, fixed vertical position, hard boundaries, initial/restored offset, and resizing. | Depends on 1 and the framing decision. Isolate it from the production screen. |
| **3. Coordinate availability** | New `CityCoordinateResolver.swift`; separate bundled coordinate lookup; narrow future selection hook in `TimeDialScreen.swift` | Resolve catalog fixtures and retain new selection evidence. Verify ambiguous records remain unresolved and IDs, ordering, and search output remain unchanged. | Requires an unresolved-entry policy. Do not modify `CityStore`, widget formats, or the deduplicator. Can be developed independently of map rendering after the data contract is defined. |
| **4. City markers** | New `CityMapMarkerView.swift`; update `WorldMapView.swift` | Use fixed-date fixtures. Verify dot anchors, custom display names, edge labels, co-located cities, and no count cap. | Depends on 1–3. Overlap and vertical visibility remain key risks. |
| **5. Selected-time synchronization** | Map/marker inputs; narrow `TimeDialScreen.swift` wiring | Pass the existing closure's `selectedInstant`. Compare map and list across wheel movement, inertia, Now reset, DST, and 12/24-hour settings. | Depends on 4. No changes are required to the time model or wheel implementation. |
| **6. List/Map integration** | `TimeDialScreen.swift`; optional small switcher view | List remains default. Reuse glass styling; preserve logo, UIKit list, sheets, selected time, rotation, and map offset. | Depends on 2–5 and switcher-placement resolution. Avoid presentation-dependent identity around shared state. |
| **7. Gesture and regression validation** | Tests and validation fixtures; only focused fixes where necessary | Test map/wheel boundary drags, diagonal drags, bottom dead zone, toggling during inertia, list reorder/swipe/details, sheets, themes, device sizes, and existing Duo compatibility. | Depends on 6. Verify hit-testing, scroll boundaries, and memory on devices. |
| **8. Expanded Duo layout** | Separate future layout work | Show list and map simultaneously using the same cities and selected instant. | Explicitly deferred; no expanded layout in this stage. |

## Validation completed during the audit

- Inspected the map asset, catalog configuration, image metadata, transparency, orientation, and edge content.
- Compared the unadjusted full-world Web Mercator projection against Natural Earth coastlines.
- Inspected the requested city models, search conversion, catalog, persistence, current-location flow, widget representation, time model, formatter, wheel, and main-screen integration.
- Inspected Figma's screenshot, geometry, crop, markers, typography, colors, switcher, glass styling, and wheel relationship without editing nodes.
- Ran `bash Tests/CitySearch/run.sh`: **129 checks passed** for geographic identity, ordering, Added state, row stability, and asynchronous search behavior.
- Verified that repository status still contained only the two pre-existing staged worldmap files at the end of the audit.

No full app build or runtime map/gesture test was performed, because the audit introduced no feature implementation. The subsequent addition of this report is documentation only.
