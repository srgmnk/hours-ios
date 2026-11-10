import XCTest
@testable import MapHarness

@MainActor final class DuoLayoutTests: XCTestCase {
    func input(_ status: DuoHingeState.Status, width: CGFloat = 951, height: CGFloat = 669, right: Bool = true) -> DuoLayoutConfiguration.Input {
        var hinge = DuoHingeState(); hinge.receive(status)
        return .init(hinge: hinge, bounds: CGRect(x: 0, y: 0, width: width, height: height),
                     safeContent: CGRect(x: right ? 0 : 84, y: 0, width: width - 84, height: height - 34),
                     railOnRight: right,
                     occlusions: [CGRect(x: right ? width - 84 : 0, y: 0, width: 84, height: width > 740 ? 124 : 174)], divisions: [])
    }
    func testGeometryCannotActivateDuoWithoutHinge() {
        for width: CGFloat in [375, 402, 440, 466, 951, 1366] {
            XCTAssertEqual(DuoLayoutConfiguration.resolve(input(.unavailable, width: width)).arrangement, .conventional)
        }
    }
    func testOuterMeasurementsAndReservedRegionClearance() {
        let c = DuoLayoutConfiguration.resolve(input(.closed, width: 466, height: 678))
        XCTAssertEqual(c.arrangement, .outer)
        XCTAssertEqual(c.list, CGRect(x: 0, y: 0, width: 382, height: 678))
        XCTAssertEqual(c.list.width - 16, 366)
        XCTAssertEqual(c.wheelCenter, CGPoint(x: 191, y: 804))
        XCTAssertEqual(c.wheelClip.width, 466)
        XCTAssertEqual(c.controls, CGRect(x: 394, y: 174, width: 48, height: 106))
        XCTAssertEqual(c.bottomInset, 34)
        XCTAssertEqual(c.mapDrawingFrame, CGRect(x: 0, y: 0, width: 466, height: 678))
        XCTAssertEqual(c.mapVisualViewport, c.mapDrawingFrame)
        XCTAssertEqual(c.blurFrame, CGRect(x: -5, y: 538, width: 477, height: 140))
    }
    func testLeadingSplitWithoutStatusOcclusionReusesTheRail() throws {
        let right = DuoLayoutConfiguration.resolve(input(.fullyOpen, width: 469, height: 669))
        var leftInput = input(.fullyOpen, width: 469, height: 669, right: false)
        leftInput.safeContent = CGRect(x: 0, y: 0, width: 469, height: 635)
        leftInput.occlusions = []
        for previous in [nil, right] {
            let left = DuoLayoutConfiguration.resolve(leftInput, previous: previous)
            XCTAssertEqual(left.arrangement, .outer)
            XCTAssertEqual(left.rail, CGRect(x: 0, y: 0, width: 84, height: 669))
            XCTAssertEqual(left.list, right.list.offsetBy(dx: 84, dy: 0))
            XCTAssertEqual(left.list.width, 385)
            XCTAssertEqual(left.controls, CGRect(x: 24, y: 24, width: 48, height: 106))
            XCTAssertEqual(left.outerSwitcherFrame, CGRect(x: 24, y: 587, width: 48, height: 48))
            XCTAssertEqual(left.wheelCenter, CGPoint(x: 276.5, y: 795))
            XCTAssertEqual(left.mapDrawingFrame, leftInput.bounds)
            XCTAssertEqual(left.mapVisualViewport?.minX, -84)
            XCTAssertEqual(DuoLayoutConfiguration.resolve(input(.fullyOpen, width: 469, height: 669), previous: left), right)
            leftInput.hinge.receive(.unavailable)
            XCTAssertEqual(DuoLayoutConfiguration.resolve(leftInput, previous: left).controls, left.controls)
        }
    }
    func testLeadingRailStillRequiresConfirmedDuoAndClearsReservations() {
        var i = input(.unavailable, width: 469, height: 669, right: false)
        i.occlusions = []
        XCTAssertEqual(DuoLayoutConfiguration.resolve(i).arrangement, .conventional)
        i.hinge.receive(.fullyOpen)
        i.safeContent = CGRect(x: 96, y: 0, width: 373, height: 635)
        let measured = DuoLayoutConfiguration.resolve(i)
        XCTAssertEqual(measured.rail.width, 96)
        XCTAssertEqual(measured.controls?.midX, 60)
        i.occlusions = [CGRect(x: 0, y: 0, width: 96, height: 124)]
        XCTAssertEqual(DuoLayoutConfiguration.resolve(i).controls?.minY, 124)
        i.divisions = [CGRect(x: 0, y: 124, width: 96, height: 545)]
        XCTAssertNil(DuoLayoutConfiguration.resolve(i).controls)
    }
    func testInnerMeasurements() {
        let c = DuoLayoutConfiguration.resolve(input(.fullyOpen))
        XCTAssertEqual(c.map, CGRect(x: 0, y: 0, width: 475.5, height: 669))
        XCTAssertEqual(c.list, CGRect(x: 475.5, y: 0, width: 391.5, height: 669))
        XCTAssertEqual(c.wheelCenter, CGPoint(x: 237.75, y: 815))
        XCTAssertEqual(c.wheelClip, c.map)
        XCTAssertEqual(c.controls, CGRect(x: 879, y: 124, width: 48, height: 106))
        XCTAssertEqual(c.mapDrawingFrame, c.map)
        XCTAssertNil(c.mapVisualViewport)
        XCTAssertEqual(c.blurFrame, CGRect(x: 0, y: 574, width: 475.5, height: 95))
    }

    func testCompactSettingsHeaderRequiresSettledFullyOpenDuo() {
        let full = DuoLayoutConfiguration.resolve(input(.fullyOpen))
        XCTAssertTrue(full.usesCompactSettingsHeader)
        for size in [CGSize(width: 375, height: 667), CGSize(width: 402, height: 874),
                     CGSize(width: 440, height: 956), CGSize(width: 951, height: 669)] {
            XCTAssertFalse(DuoLayoutConfiguration.resolve(input(.unavailable,
                width: size.width, height: size.height)).usesCompactSettingsHeader)
        }
        for right in [true, false] {
            for status: DuoHingeState.Status in [.closed, .partiallyOpen, .fullyOpen] {
                XCTAssertFalse(DuoLayoutConfiguration.resolve(input(status, width: 469,
                    right: right), previous: full).usesCompactSettingsHeader)
            }
        }
        let partial = DuoLayoutConfiguration.resolve(input(.partiallyOpen), previous: full)
        XCTAssertFalse(partial.usesCompactSettingsHeader)
        XCTAssertTrue(DuoLayoutConfiguration.resolve(input(.fullyOpen), previous: partial).usesCompactSettingsHeader)
        var closing = input(.fullyOpen)
        closing.hinge.receive(.closed)
        XCTAssertFalse(DuoLayoutConfiguration.resolve(closing, previous: full).usesCompactSettingsHeader)
        var unavailable = input(.fullyOpen)
        unavailable.hinge.receive(.unavailable)
        XCTAssertTrue(DuoLayoutConfiguration.resolve(unavailable, previous: full).usesCompactSettingsHeader)
        XCTAssertFalse(DuoLayoutConfiguration.resolve(unavailable, previous: partial).usesCompactSettingsHeader)
        var missingGeometry = input(.fullyOpen)
        missingGeometry.bounds = .zero
        XCTAssertFalse(DuoLayoutConfiguration.resolve(missingGeometry, previous: full).usesCompactSettingsHeader)
    }
    func testOuterSwitcherUsesControlAxisAndBottomSafeArea() {
        for right in [true, false] {
            var i = input(.closed, width: 466, height: 678, right: right)
            for inset: CGFloat in [0, 34, 50] {
                i.safeContent.size.height = 678 - inset
                let c = DuoLayoutConfiguration.resolve(i)
                let frame = try! XCTUnwrap(c.outerSwitcherFrame)
                XCTAssertEqual(frame.size, CGSize(width: 48, height: 48))
                XCTAssertEqual(frame.midX, c.controls!.midX)
                XCTAssertEqual(frame.maxY, c.rail.maxY - max(inset, 24))
                XCTAssertTrue(c.rail.contains(frame))
                XCTAssertFalse(frame.intersects(c.controls!))
            }
        }
    }
    func testRailSwitcherIsIsolatedToClosedDuo() {
        for status: DuoHingeState.Status in [.unavailable, .partiallyOpen, .fullyOpen] {
            XCTAssertNil(DuoLayoutConfiguration.resolve(input(status)).outerSwitcherFrame)
        }
        var i = input(.closed, width: 466, height: 678)
        let closed = DuoLayoutConfiguration.resolve(i)
        XCTAssertEqual(closed.outerSwitcherFrame, CGRect(x: 394, y: 596, width: 48, height: 48))
        i.hinge.receive(.unavailable)
        XCTAssertEqual(DuoLayoutConfiguration.resolve(i, previous: closed).outerSwitcherFrame,
                       closed.outerSwitcherFrame, "Missing hinge delivery must not move the outer button")
    }
    func testPartialLaunchSplitsTheCanvasIncludingTheRail() {
        for size in [CGSize(width: 466, height: 678), CGSize(width: 669, height: 951),
                     CGSize(width: 740, height: 400), CGSize(width: 951, height: 669),
                     CGSize(width: 1023.5, height: 620.5)] {
            for right in [true, false] {
                let i = input(.partiallyOpen, width: size.width, height: size.height, right: right)
                let c = DuoLayoutConfiguration.resolve(i)
                XCTAssertEqual(c.arrangement, .inner)
                XCTAssertFalse(c.isTransition)
                XCTAssertEqual(c.map.width + (right ? 0 : c.rail.width), i.bounds.width / 2)
                XCTAssertEqual(c.list.width + (right ? c.rail.width : 0), i.bounds.width / 2)
                XCTAssertEqual(c.map.minX, c.content.minX)
                XCTAssertEqual(c.map.maxX, c.list.minX)
                XCTAssertEqual(c.list.maxX, c.content.maxX)
                XCTAssertEqual(c.map.union(c.list), c.content)
                XCTAssertEqual(c.wheelCenter.x, c.map.midX)
                XCTAssertEqual(c.wheelCenter.y, c.map.maxY + 146)
                XCTAssertEqual(c.wheelClip, c.map)
                XCTAssertEqual(c.mapDrawingFrame, c.map)
                XCTAssertEqual(c.blurFrame.minX, c.map.minX)
                XCTAssertEqual(c.blurFrame.maxX, c.map.maxX)
                XCTAssertEqual(c.bottomInset, 34)
                XCTAssertEqual(c.controls, DuoLayoutConfiguration.resolve(input(.fullyOpen,
                    width: size.width, height: size.height, right: right)).controls)
                for region in i.occlusions {
                    XCTAssertFalse(c.map.intersects(region))
                    XCTAssertFalse(c.list.intersects(region))
                    XCTAssertFalse(c.wheelClip.intersects(region))
                }
            }
        }
    }
    func testPartialAndFullyOpenTransitionsFollowRealWindowResizing() {
        let fullInput = input(.fullyOpen)
        let full = DuoLayoutConfiguration.resolve(fullInput)
        var previous = full
        for _ in 0..<10 {
            let partial = DuoLayoutConfiguration.resolve(input(.partiallyOpen, width: 800), previous: previous)
            XCTAssertTrue(partial.isInner)
            XCTAssertEqual(partial.map.width, 400)
            XCTAssertEqual(partial.list.width, 316)
            previous = DuoLayoutConfiguration.resolve(fullInput, previous: partial)
            XCTAssertEqual(previous, full, "Fully open geometry must remain unchanged")
        }
        let closed = DuoLayoutConfiguration.resolve(input(.closed, width: 466, height: 678), previous: previous)
        XCTAssertEqual(closed, DuoLayoutConfiguration.resolve(input(.closed, width: 466, height: 678)))
    }
    func testLandscapePosturesShareWindowMidpointWithoutDoubleSubtractingRail() {
        for right in [true, false] {
            for size in [CGSize(width: 951, height: 669), CGSize(width: 1023.5, height: 620.5)] {
                let fullInput = input(.fullyOpen, width: size.width, height: size.height, right: right)
                let full = DuoLayoutConfiguration.resolve(fullInput)
                var partialInput = fullInput; partialInput.hinge.receive(.partiallyOpen)
                partialInput.divisions = [CGRect(x: size.width / 2 - 20, y: 0, width: 40, height: size.height)]
                var previous = full
                for _ in 0..<20 {
                    for next in [partialInput, fullInput] {
                        let current = DuoLayoutConfiguration.resolve(next, previous: previous)
                        XCTAssertEqual(current.arrangement, .inner)
                        XCTAssertFalse(current.isTransition)
                        XCTAssertEqual(current.map, full.map)
                        XCTAssertEqual(current.list, full.list)
                        XCTAssertEqual(current.listViewport, full.listViewport)
                        XCTAssertEqual(current.mapDrawingFrame, full.mapDrawingFrame)
                        XCTAssertEqual(current.wheelCenter, full.wheelCenter)
                        XCTAssertEqual(current.deltaCenter, full.deltaCenter)
                        XCTAssertEqual(current.blurFrame, full.blurFrame)
                        XCTAssertEqual(current.controls, full.controls)
                        XCTAssertEqual(current.map.maxX, next.bounds.midX)
                        XCTAssertEqual(current.map.width + (right ? 0 : current.rail.width), size.width / 2)
                        XCTAssertEqual(current.list.width + (right ? current.rail.width : 0), size.width / 2)
                        XCTAssertEqual(current.map.width + current.list.width + current.rail.width, size.width)
                        previous = current
                    }
                }
                // Full-layout history must not make a narrow Split View pane a split.
                var split = input(.fullyOpen, width: 469, height: 669, right: right)
                split.hinge.receive(.unavailable)
                XCTAssertEqual(DuoLayoutConfiguration.resolve(split, previous: full).arrangement, .outer)
            }
        }
    }

    func testLandscapeStatusAndDivisionDeliveryNeverSelectSinglePane() {
        for right in [true, false] {
            var full = input(.fullyOpen, right: right)
            let settled = DuoLayoutConfiguration.resolve(full)
            var partial = full; partial.hinge.receive(.partiallyOpen)
            let seam = CGRect(x: full.bounds.midX - 20, y: full.bounds.minY, width: 40, height: full.bounds.height)
            var partialWithSeam = partial; partialWithSeam.divisions = [seam]
            var fullWithSeam = full; fullWithSeam.divisions = [seam]
            var missingStatus = partialWithSeam; missingStatus.hinge.receive(.unavailable)
            var previous = settled
            // Both independent delivery orders, in both directions, plus nil status.
            for next in [partial, partialWithSeam, fullWithSeam, missingStatus, full,
                         fullWithSeam, partialWithSeam, missingStatus, partial, full] {
                let current = DuoLayoutConfiguration.resolve(next, previous: previous)
                XCTAssertEqual(current.arrangement, .inner)
                XCTAssertEqual(current.map, settled.map)
                XCTAssertEqual(current.listViewport, settled.listViewport)
                XCTAssertEqual(current.mapRenderingViewport, settled.mapRenderingViewport)
                XCTAssertEqual(current.mapDrawingFrame, settled.mapDrawingFrame)
                XCTAssertEqual(current.wheelCenter, settled.wheelCenter)
                XCTAssertEqual(current.controls, settled.controls)
                if !next.divisions.isEmpty {
                    XCTAssertFalse(current.mapViewport.intersects(seam), "Touch clearance is retained")
                }
                previous = current
            }
            // Genuine size changes still resolve from current bounds.
            full.bounds.size.width = 1000; full.safeContent.size.width = 916
            if right { full.occlusions = [CGRect(x: 916, y: 0, width: 84, height: 124)] }
            let resized = DuoLayoutConfiguration.resolve(full, previous: previous)
            XCTAssertEqual(resized.map.maxX, 500)
            XCTAssertNotEqual(resized.mapRenderingViewport, settled.mapRenderingViewport)
        }
    }

    func testLandscapeSeamAllowanceDoesNotAcceptOcclusionsOrUnknownDivisions() {
        var full = input(.fullyOpen)
        let previous = DuoLayoutConfiguration.resolve(full)
        for division in [CGRect(x: 400, y: 0, width: 40, height: 669),
                         CGRect(x: 455.5, y: 0, width: 60, height: 669),
                         CGRect(x: 455.5, y: 0, width: 40, height: 300)] {
            full.divisions = [division]
            XCTAssertEqual(DuoLayoutConfiguration.resolve(full, previous: previous).arrangement, .outer)
        }
        full.divisions = [CGRect(x: 455.5, y: 0, width: 40, height: 669)]
        full.occlusions.append(CGRect(x: 0, y: 0, width: 476, height: 669))
        XCTAssertEqual(DuoLayoutConfiguration.resolve(full, previous: previous).arrangement, .outer)
        var conventional = full; conventional.hinge = DuoHingeState()
        XCTAssertEqual(DuoLayoutConfiguration.resolve(conventional, previous: previous).arrangement, .conventional)
        var narrow = input(.fullyOpen, width: 469, height: 669)
        narrow.divisions = [CGRect(x: narrow.bounds.midX - 20, y: 0, width: 40, height: 669)]
        XCTAssertEqual(DuoLayoutConfiguration.resolve(narrow, previous: previous).arrangement, .outer)
        var smallerPartial = input(.partiallyOpen, width: 740, height: 400)
        smallerPartial.divisions = [CGRect(x: 350, y: 0, width: 40, height: 400)]
        let smaller = DuoLayoutConfiguration.resolve(smallerPartial)
        XCTAssertEqual(smaller.mapRenderingViewport, smaller.mapViewport)
    }

    func testPartialProportionsSurviveMissingHingeAndGeometry() {
        var i = input(.partiallyOpen, width: 669, height: 951)
        let partial = DuoLayoutConfiguration.resolve(i)
        i.hinge.receive(.unavailable)
        let missingHinge = DuoLayoutConfiguration.resolve(i, previous: partial)
        XCTAssertTrue(missingHinge.isInner)
        XCTAssertTrue(missingHinge.isTransition)
        XCTAssertEqual(missingHinge.map, partial.map)
        XCTAssertEqual(missingHinge.list, partial.list)
        i.bounds = .zero
        let missingGeometry = DuoLayoutConfiguration.resolve(i, previous: missingHinge)
        XCTAssertEqual(missingGeometry.map, partial.map)
        XCTAssertEqual(missingGeometry.list, partial.list)
    }
    func testPartialSplitUsesContainerOriginAndRailMeasurement() {
        var i = input(.partiallyOpen)
        i.bounds = CGRect(x: 17, y: 23, width: 701, height: 550)
        i.safeContent = CGRect(x: 17, y: 23, width: 629, height: 529)
        i.occlusions = [CGRect(x: 646, y: 23, width: 72, height: 124)]
        let c = DuoLayoutConfiguration.resolve(i)
        XCTAssertEqual(c.map, CGRect(x: 17, y: 23, width: 350.5, height: 550))
        XCTAssertEqual(c.list, CGRect(x: 367.5, y: 23, width: 278.5, height: 550))
        XCTAssertEqual(c.wheelCenter.x, 192.25)
        XCTAssertEqual(c.bottomInset, 21)
        XCTAssertEqual(c.controls, CGRect(x: 658, y: 147, width: 48, height: 106))
    }
    func testOuterBackgroundSurvivesTransientHingeDeliveryWithoutChangingInteractionFrames() {
        var i = input(.closed, width: 466, height: 678)
        let previous = DuoLayoutConfiguration.resolve(i)
        i.hinge.receive(.unavailable)
        let c = DuoLayoutConfiguration.resolve(i, previous: previous)
        XCTAssertTrue(c.isTransition)
        XCTAssertEqual(c.mapDrawingFrame, i.bounds)
        XCTAssertEqual(c.map, previous.map)
        XCTAssertEqual(c.list, previous.list)
        XCTAssertEqual(c.controls, previous.controls)
        XCTAssertEqual(c.wheelClip, c.map)
        XCTAssertEqual(c.blurFrame, CGRect(x: 0, y: 538, width: 466, height: 140))
    }
    func testCapabilitySurvivesMissingHingeAndGeometry() {
        var i = input(.fullyOpen)
        let previous = DuoLayoutConfiguration.resolve(i)
        i.hinge.receive(.unavailable)
        XCTAssertEqual(DuoLayoutConfiguration.resolve(i, previous: previous).arrangement, .inner)
        i.bounds = .zero
        let held = DuoLayoutConfiguration.resolve(i, previous: previous)
        XCTAssertEqual(held.map, previous.map)
        XCTAssertTrue(held.isTransition)
        let closedBeforeResize = DuoLayoutConfiguration.resolve(input(.closed), previous: previous)
        XCTAssertTrue(closedBeforeResize.isInner)
        XCTAssertTrue(closedBeforeResize.isTransition)
    }
    func testPartialPaintsToTheCanvasCenterWithoutMovingTheRail() {
        var i = input(.partiallyOpen)
        let previous = DuoLayoutConfiguration.resolve(input(.fullyOpen))
        XCTAssertTrue(DuoLayoutConfiguration.resolve(i, previous: previous).isInner)
        i.divisions = [CGRect(x: 455.5, y: 0, width: 40, height: 669)]
        for right in [true, false] {
            i = input(.partiallyOpen, right: right)
            i.divisions = [CGRect(x: 455.5, y: 0, width: 40, height: 669)]
            let c = DuoLayoutConfiguration.resolve(i, previous: previous)
            XCTAssertTrue(c.isInner)
            XCTAssertFalse(c.isTransition)
            XCTAssertEqual(c.map.width, right ? 475.5 : 391.5)
            XCTAssertEqual(c.list.width, right ? 391.5 : 475.5)
            XCTAssertEqual(c.map.minX, c.content.minX)
            XCTAssertEqual(c.list.maxX, c.content.maxX)
            XCTAssertEqual(c.list.minX, i.bounds.midX)
            XCTAssertEqual(c.map.maxX, i.bounds.midX)
            XCTAssertTrue(c.map.contains(c.mapViewport))
            XCTAssertTrue(c.list.contains(c.listViewport))
            XCTAssertEqual(c.mapDrawingFrame, c.map)
            XCTAssertEqual(c.listViewport, c.list)
            XCTAssertFalse(c.wheelClip.intersects(i.divisions[0]))
            XCTAssertEqual(c.blurFrame.maxX, i.bounds.midX)
            XCTAssertEqual(c.wheelCenter.x, c.map.midX)
            XCTAssertEqual(c.mapViewport.width, right ? 455.5 : 371.5)
            XCTAssertEqual(c.listViewport.width, right ? 391.5 : 475.5)
            XCTAssertEqual(c.wheelCenter.y, 815)
            XCTAssertEqual(c.controls, previous.controls.map { right ? $0 : CGRect(x: 24, y: 124, width: 48, height: 106) })
            XCTAssertFalse(c.map.intersects(c.rail))
            XCTAssertFalse(c.list.intersects(c.rail))
            XCTAssertNil(c.mapVisualViewport)
            XCTAssertEqual(c.mapRenderingViewport, c.map)
            XCTAssertEqual(c.mapInteractionViewport?.width, c.mapViewport.width)
            XCTAssertEqual(DuoLayoutConfiguration.resolve(i), c)
        }
        i = input(.fullyOpen, width: 466, height: 678)
        XCTAssertEqual(DuoLayoutConfiguration.resolve(i, previous: previous).arrangement, .outer)
    }
    func testUnavailablePartialPanelStillUsesSafeSinglePaneFallback() {
        var i = input(.partiallyOpen)
        i.occlusions.append(CGRect(x: 0, y: 0, width: 476, height: 669))
        let c = DuoLayoutConfiguration.resolve(i)
        XCTAssertEqual(c.arrangement, .outer)
        for region in i.occlusions {
            XCTAssertFalse(c.mapDrawingFrame.intersects(region))
            XCTAssertFalse(c.listViewport.intersects(region))
            XCTAssertFalse(c.wheelClip.intersects(region))
        }
    }
    func testRTLPhysicalRailAndNoDoubleMargins() {
        let i = input(.closed, width: 466, height: 678, right: false)
        let c = DuoLayoutConfiguration.resolve(i)
        XCTAssertEqual(c.content.minX, 84)
        XCTAssertEqual(c.controls?.minX, 24)
        XCTAssertEqual(c.controls?.minY, 174)
        XCTAssertFalse(c.controls!.intersects(i.occlusions[0]))
        XCTAssertEqual(c.mapVisualViewport, CGRect(x: -84, y: 0, width: 466, height: 678))
    }
    func testConventionalFormulaIsUnchanged() {
        for size in [CGSize(width: 375, height: 667), CGSize(width: 402, height: 874), CGSize(width: 440, height: 956)] {
            let g = WorldMapGeometryProfile.conventional.canvas(in: size)
            let scale = max(size.width / 393, size.height / 852)
            XCTAssertEqual(g.side, 1129 * scale)
            XCTAssertEqual(g.top, -13 * scale)
        }
    }
    func testInnerMapCropAndProportionalGeometry() {
        let p = WorldMapGeometryProfile.duoInner
        let g = p.canvas(in: CGSize(width: 527, height: 669))
        XCTAssertEqual(g.side, 1022); XCTAssertEqual(g.top, -97)
        XCTAssertEqual(527 / 2 - WorldMapGeometryProfile.duoInitialCenter * g.side, -474, accuracy: 0.00001)
        let larger = p.canvas(in: CGSize(width: 1054, height: 1338))
        XCTAssertEqual(larger.side, 2044); XCTAssertEqual(larger.top, -194)
    }
}
