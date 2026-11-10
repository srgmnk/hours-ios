# Map pins and night lights — 2026-11-09

## Design source and exact measurements

Read directly from [Figma Day, 746:10045](https://www.figma.com/design/YH7MouHlewHKjKVJDtCKXh/Hours-iOS?node-id=746-10045) and [Dark, 746:10108](https://www.figma.com/design/YH7MouHlewHKjKVJDtCKXh/Hours-iOS?node-id=746-10108), including node fills, strokes, opacity, effects and render bounds. Both frames use the same components. The supplied screenshot was not used to estimate measurements.

| Property | Ordinary pin | Primary pin |
| --- | --- | --- |
| Node | 746:10088 | 746:10125, children 746:10083 and 746:10126 |
| Shape | Circle | Concentric circles |
| Orange fill diameter | 8 pt | 16 pt |
| Fill | sRGB (1, 64/255, 0), **#FF4000** | Same |
| Outline | **#FFFFFF**, 2 pt, outside | Same |
| Total outlined diameter | **12 pt** | **20 pt** |
| Center | Orange | **6 pt white circle**, no stroke |
| Component indicator frame | 8 × 8 pt before outside stroke | 20 × 20 pt |
| Opacity | Node, fill and stroke all 100% | Same |
| Shadow | Black 20%, offset (0, 4), Figma radius 8, spread 0 | Same |
| Export including shadow | 28 × 28 pt, 84 × 84 pixels at 3× | 36 × 36 pt, 108 × 108 pixels at 3× |
| Light/Dark variation | None | None |

The Primary circle is positioned at (2.5, 2) within the Figma frame; its white center starts at (7.5, 7). The implementation registers the actual circle center to the geographic coordinate rather than the frame's half-point horizontal offset. The exports' geographic anchors are (14, 10) and (18, 14), including shadow padding.

| Night-light property | Exact Figma value |
| --- | --- |
| Component | 746:10182, 6 × 6 pt |
| Core | 2 × 2 pt circle at (2, 2), opacity 1, no stroke |
| Core color | sRGB **(1, 0.9342057108879089, 0.7368227243423462)**; nearest 8-bit hex **#FFEEBC** |
| Glow | 6 × 6 pt circle, radius 3 pt, opacity **0.6** |
| Glow color | sRGB **(1, 0.75, 0)**; nearest 8-bit hex **#FFBF00** |
| Blur | Normal layer blur, **4 pt** |
| Gradient | None: solid fills plus layer blur |
| Export including blur | **14 × 14 pt**, 42 × 42 pixels at 3× |
| Light/Dark variation | None |
| Solar activation | Existing smoothstep: invisible at elevation ≥ −3°, full at ≤ −9°, 0.5 at −6° |

The three PNGs are direct Figma exports with effects baked at 3×, not re-created approximations. Original `worldmap-marker` artwork is retained for historical comparison. Labels retain the existing app typography and theme styling; only pin ink is made theme invariant.

## Implementation and interaction boundaries

`WorldMapObservedContent` resolves Primary from the authoritative saved city order (the same source used by City Details and the clock), before geographic filtering. It passes the canonical city ID through `WorldMapView` and its adapter. Marker reuse and Primary styling compare IDs only. A frozen selected instant does not prevent live Primary updates. An unresolved Primary city never promotes the first visible marker.

Each city retains its existing single marker. Primary markers are brought above overlapping ordinary markers, including inside groups. Shared labels retain the same members and chooser IDs. Group membership uses the pre-redesign dot and label reference geometry; collision placement and hit testing use the new actual 12/20-point footprints. The Primary label has 6 additional screen points of clearance. No gesture-delegate, haptic, scrolling, chooser, City Details or projection code was changed.

The established label transform remains 1022/1129. Pin exports compensate for it, yielding fixed 12/20-point outlined circles across conventional, outer, inner, portrait, partial and Split View fixtures. Map artwork, map scales and camera arithmetic are unchanged.

`NightRenderer` creates one immutable 42 × 42 RGBA sprite texture (7,056 source bytes) and reuses it for every light and update. It uses the existing light pipeline, instanced quads, render pass, command queue and reusable triple buffers. No full-resolution processing, animation, timer, display link or extra rendering pass is introduced. The fragment samples premultiplied color; existing solar visibility fades the entire sprite. Visibility culling now includes the 7-point glow extent to avoid edge clipping. Solar shadow shader and appearance opacity are unchanged.

## Immutable selection: exactly 50 base lights

`DecorativeCityIDs.catalogIDs` is the production manifest, ordered explicitly by region. This is a visual geographic composition, not a current population ranking. All entries are drawn from the original 152. `OriginalDecorativeCityIDs` and its frozen fixtures remain unchanged. No city coordinate, canonical identity, search catalog record or persistence format changed.

| Region | Count | Cities |
| --- | ---: | --- |
| North America | 8 | Vancouver, Los Angeles, Denver, Chicago, Toronto, New York, Miami, Mexico City |
| South America | 6 | Bogotá, Lima, São Paulo, Rio de Janeiro, Buenos Aires, Santiago |
| Europe | 7 | London, Paris, Madrid, Rome, Berlin, Moscow, Istanbul |
| Africa | 7 | Casablanca, Lagos, Cairo, Addis Ababa, Nairobi, Johannesburg, Cape Town |
| Asia | 17 | Dubai, Tehran, Karachi, Mumbai, Delhi, Dhaka, Bangkok, Singapore, Jakarta, Manila, Hong Kong, Shanghai, Beijing, Seoul, Tokyo, Novosibirsk, Vladivostok |
| Oceania | 5 | Perth, Melbourne, Sydney, Auckland, Suva |
| Total | **50** | |

North America covers Pacific, interior, Atlantic and Mexican/Caribbean longitudes. South America covers the Andes, Brazil and Southern Cone. Europe spans west, Mediterranean, central/east and the Bosporus (Istanbul is counted here once). Africa covers northwest, west, northeast, east and south. Asia balances major west/south/southeast/east metropolitan areas with northern longitude coverage in Siberia and the Russian Far East. Oceania spans both Australian coasts, New Zealand and the Pacific. Suva, Perth, Denver and the northern Asian entries deliberately improve geographic spread rather than maximizing population rank. The historical set has limited central-African and central-Pacific coverage; no identities were invented to fill those gaps.

Saved cities remain an independent dynamic input. A saved city in the 50 is deduplicated by canonical identity. An omitted original city (tested with Boston), an imported city (Samara), or a remote city with coordinates still contributes its saved light. Saving all original 152 produces 152 total lights, not 202. Visible markers remain driven exclusively by saved cities.

## Changed files

- `Hours/Features/WorldMap/WorldMapObservedContent.swift` — pass authoritative Primary identity.
- `Hours/Features/WorldMap/WorldMapView.swift` — exact pin assets, identity updates, overlap order and actual hit/collision bounds; legacy group membership preserved.
- `Hours/Features/WorldMap/DecorativeCityIDs.swift` — new immutable 50-city manifest.
- `Hours/Features/WorldMap/NightCityLights.swift` — curated base and measured appearance constants.
- `Hours/Features/WorldMap/DayNightOverlay.swift` — shared tiny sprite texture and glow culling extent.
- `Hours/Resources/DayNight.metal` — sample the sprite through the existing light draw.
- `Hours/Resources/Assets.xcassets/map/worldmap-pin.imageset/` — Figma ordinary pin and asset metadata.
- `Hours/Resources/Assets.xcassets/map/worldmap-primary-pin.imageset/` — Figma Primary pin and asset metadata.
- `Hours/Resources/Assets.xcassets/map/worldmap-night-light.imageset/` — Figma light and asset metadata.
- `Tests/Duo/WorldMapSizingTests.swift` — updated approved dot size and additional profile fixtures.
- `Tests/Duo/MapVisualRedesignTests.swift` — appearance, Primary identity, live observation, grouping, region distribution, idle invalidation and screenshots.
- `Tests/Duo/MapRenderingCostTests.swift` — bounded offscreen event-render measurement.
- `Tests/CatalogIntegration/IntegrationTests.swift` and `run.sh` — 50-city expectations, historical coordinate comparison and saved-light preservation.
- This report.

Pre-existing uncommitted Duo/onboarding changes were preserved. No staging, commit, push, version/build change, Git exclusion change or generated build product is part of this work. Temporary screenshots, isolated test hosts, build products and detailed logs are under `/private/tmp/Hours-MapRedesign-2026-11-09/`.

## Validation

- **Debug and Release builds passed**, scheme Hours, including `HoursWidgetExtension`. Debug built both simulator architectures; Release built arm64. All products were outside the repository.
- **57 distinct Duo-hosted test cases passed** across the map, sizing, interaction, alignment, geometry, portrait/presentation and new visual/rendering suites after correcting the new identity fixture. One existing repeated-dismissal test still fails (below).
- **15 of 16 conventional-iPhone cases passed** on the iOS 27.0 iPhone QA simulator: all four visual/identity/idle/capture cases, both sizing/capture cases and nine interaction cases. The same existing repeated-dismissal case fails.
- **3,270 catalog integration checks plus 130 existing geographic/search checks passed**. Coverage includes real CityStore save/reload with isolated I/O, ID and coordinate preservation, original catalog fixtures, removed-base saved-city lights and deduplication.
- **`git diff --check` passed**. All initially modified out-of-scope files retain exactly their initial diffs. The 3,000-city catalog, coordinates, historical manifest, projection, artwork, project configuration, version/build numbers and `.gitignore` have no new changes.
- Primary changes were tested with a frozen clock, identical names/time zones and an unresolved first saved city. Marker views are reused. Group membership and all chooser identities are retained; single Primary selection reaches the existing City Details callback.
- Geometric layout fixtures cover conventional portrait, Duo outer, fully/partially open landscape, fully/partially open portrait and a narrow Split View pane. Fixed 12/20-point dot sizes, geographic anchors, collision avoidance, selection regions and repeated world wrap are asserted.
- Visible overlay idle test renders once, repeats 100 unchanged date/camera/light updates, waits, and verifies no pending redraw, no light revision change, reused buffer identities, and paused/on-demand Metal configuration. No production diagnostic counter or additional rendering loop was added.

### Known baseline failure

`WorldMapInteractionTests.testRepeatedChooserDismissalKeepsMainThreadAndMapResponsive` fails when reopening after a programmatic dismissal: the dismissed UIAlertController remains referenced and the existing chooser guard rejects the next presentation. The identical test fails against the preserved, unedited pre-change app on the same Duo simulator, and also fails on the conventional iPhone after the change. A separate-scope diagnostic still reproduced retention; this is not claimed to be just a test-local lifetime issue. The production chooser/gesture code and this pre-existing test were left untouched. A focused new test verifies that a group containing Primary opens with every member, duplicate names are disambiguated, and individual Primary selection reaches the existing callback. Repeated interactive Cancel/selection on hardware remains to be checked.

### Performance measurement

Bounded offscreen render of the same 393 × 852 viewport, same solar uniforms/camera, all base lights at full visibility, 5 warmups then 50 completed draws. Each run uses the original/new renderer and the same `Apple iOS simulator GPU`. Medians are observations, not a hardware performance guarantee.

| Measurement | Before | After |
| --- | ---: | ---: |
| Base light records | 152 | 50 |
| Wrapped instances (3 copies) | 456 | 150 |
| Light vertices | 2,736 | 900 |
| CPU encoding median | 0.0212 ms | 0.0367 ms |
| GPU duration median | 0.0299 ms | 0.0410 ms |
| Encode through completion median | 0.4915 ms | 0.6440 ms |
| Light sprite | None | One shared 42 × 42 texture (7,056 source bytes) |
| Additional passes / idle loops | 0 | 0 |

The brighter, wider sprite adds texture sampling and more covered fragments; fewer cities do not imply lower fragment cost. The measured GPU increase is about 0.011 ms per event. Base visibility calculations and instanced geometry decrease by 67.1%; buffers retain the existing minimum capacity. Idle rendering activity is unchanged. No hardware GPU/power/thermal trace was collected.

### Screenshots and visual review

Screenshots are native map-view renders; they are not entire app/device-chrome captures. The before host was copied from the actual initial working tree, including the user's Duo/onboarding changes. Matched before/after fixtures use identical camera, cities, dates and sizes. The 42-image matrix spans seven geometry profiles × two themes × daylight/twilight/full night. Additional captures cover standalone Primary and the actual conventional iPhone simulator host. The split/partial fixtures validate geometry, not a live hinge transition.

- [Night, matching before/after in both themes](/private/tmp/Hours-MapRedesign-2026-11-09/comparison-night.png)
- [Twilight, matching before/after in both themes](/private/tmp/Hours-MapRedesign-2026-11-09/comparison-twilight.png)
- [Daylight, matching before/after in both themes](/private/tmp/Hours-MapRedesign-2026-11-09/comparison-day.png)
- [Standalone Primary and ordinary pins in both themes](/private/tmp/Hours-MapRedesign-2026-11-09/primary-light-dark.png)
- [All seven layout fixtures, Light](/private/tmp/Hours-MapRedesign-2026-11-09/layouts-light.png)
- [All seven layout fixtures, Dark](/private/tmp/Hours-MapRedesign-2026-11-09/layouts-dark.png)
- [Duo portrait at twilight](/private/tmp/Hours-MapRedesign-2026-11-09/after-screens/redesign-open-portrait-light-twilight.png)
- [Grouped Primary at full night](/private/tmp/Hours-MapRedesign-2026-11-09/after-screens/redesign-iphone-dark-night.png)
- [Conventional iPhone simulator](/private/tmp/Hours-MapRedesign-2026-11-09/iphone-screens/redesign-iphone-light-day.png)

Asset inspection confirms exact opaque orange (255,64,0), white (255,255,255), and 84/108/42-pixel export sizes. Visual review confirms matching pins in both themes, visible amber glow, correct registration, and no observed clipping in the reviewed fixtures. Grouped labels can move above pins under the existing collision solver. Original label typography and theme-dependent text color are deliberately retained, so labels are not a claim of Figma text parity.

### Remaining limits

Physical-device haptics, touch/deceleration interruption sequences, live Duo hinge/Split View transitions and hardware power/performance were not verified. The existing repeated chooser-dismissal regression prevents an all-green interaction-suite claim. Figma effect fidelity comes from the direct 3× exports; the existing one-sample-per-screen-point Metal surface still controls light rasterization. Temporary screenshot links depend on retaining the `/private/tmp` artifacts.
