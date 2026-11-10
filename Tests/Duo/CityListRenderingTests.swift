import XCTest
import SwiftUI
@testable import MapHarness

@MainActor final class CityListRenderingTests: XCTestCase {
    func testDuoCardsKeepPaintedGapsWhenCrossingTheDisplayEdge() async throws {
        let scene = try XCTUnwrap(UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first)
        let previousKeyWindow = scene.windows.first(where: \.isKeyWindow)
        let window = UIWindow(windowScene: scene)
        let parent = UIViewController()
        parent.additionalSafeAreaInsets.bottom = 34
        window.rootViewController = parent
        window.makeKeyAndVisible()
        defer {
            window.isHidden = true
            previousKeyWindow?.makeKeyAndVisible()
        }

        let controller = CityListReorderViewController()
        parent.addChild(controller)
        parent.view.addSubview(controller.view)
        controller.view.frame = CGRect(x: 0, y: 0, width: 340, height: 669)
        controller.didMove(toParent: parent)
        let cities = (0..<6).map {
            City(name: "City \($0)", timeZoneID: "UTC", canonicalID: "paint-test-\($0)")
        }
        controller.prepareDuoLayout(viewport: controller.view.bounds.size)
        let list = controller.collectionView
        var checkedGaps = 0
        let configurations: [(viewport: CGSize, bottomInset: CGFloat)] = [
            (CGSize(width: 382, height: 678), 130), // Outer
            (CGSize(width: 455.667, height: 669), 34), // Folding
            (CGSize(width: 340, height: 669), 34) // Inner
        ]
        for configuration in configurations {
            controller.view.frame.size = configuration.viewport
            controller.prepareDuoLayout(viewport: configuration.viewport)
            for style in [CityViewPreference.basic, .compact] {
                controller.apply(
                    cities: cities, selectedInstant: Date(timeIntervalSince1970: 1793250000),
                    userCurrentLocationItem: nil, cityViewPreference: style,
                    topInset: 25, bottomInset: configuration.bottomInset, cardBackgroundColor: Color(uiColor: .magenta)
                )
                for offset: CGFloat in [0, -120, -200, 80, 180, 275, 450] {
                    list.setContentOffset(CGPoint(x: 0, y: offset), animated: false)
                    controller.view.layoutIfNeeded()
                    try await Task.sleep(for: .milliseconds(50))
                    list.layoutIfNeeded()
                    XCTAssertGreaterThan(list.safeAreaInsets.bottom, 0, "Exercise a real inherited safe area")
                    let format = UIGraphicsImageRendererFormat()
                    format.scale = 1
                    format.opaque = true
                    format.preferredRange = .standard
                    let image = UIGraphicsImageRenderer(size: list.bounds.size, format: format).image { _ in
                        XCTAssertTrue(list.drawHierarchy(in: CGRect(origin: .zero, size: list.bounds.size), afterScreenUpdates: true))
                    }
                    let cg = try XCTUnwrap(image.cgImage)
                    XCTAssertEqual(cg.bitsPerPixel, 32)
                    let bytes = try XCTUnwrap(cg.dataProvider?.data)
                    let pixels = try XCTUnwrap(CFDataGetBytePtr(bytes))
                    let leadingAlpha = [CGImageAlphaInfo.first, .premultipliedFirst, .noneSkipFirst].contains(cg.alphaInfo)
                    let littleEndian = cg.bitmapInfo.contains(.byteOrder32Little)
                    let green = leadingAlpha == littleEndian ? 1 : 2
                    func paintedFraction(at y: Int) -> Double {
                        let left = 30, right = cg.width - 30
                        var count = 0
                        for x in left..<right {
                            let p = y * cg.bytesPerRow + x * 4
                            if pixels[p + green - 1] > 240 && pixels[p + green] < 20 && pixels[p + green + 1] > 240 {
                                count += 1
                            }
                        }
                        return Double(count) / Double(right - left)
                    }
                    let paths = list.indexPathsForVisibleItems.sorted()
                    XCTAssertFalse(paths.isEmpty, "The fixture must display actual hosted cells")
                    for path in paths {
                        let cell = try XCTUnwrap(list.cellForItem(at: path))
                        XCTAssertEqual(cell.safeAreaInsets, .zero)
                        let expectedHeight: CGFloat = style == .compact ? 88 : 140
                        XCTAssertEqual(cell.frame.height, expectedHeight, accuracy: 0.34)
                    }
                    for (a, b) in zip(paths, paths.dropFirst()) where b.item == a.item + 1 {
                        let first = try XCTUnwrap(list.cellForItem(at: a))
                        let next = try XCTUnwrap(list.cellForItem(at: b))
                        XCTAssertEqual(next.frame.minY - first.frame.maxY, 8, accuracy: 0.34)
                        let y = Int((first.frame.maxY + 4 - list.contentOffset.y).rounded())
                        guard y > 40, y < cg.height - 12 else { continue }
                        // The original defect passes the frame assertion above but
                        // paints the next card over this supposedly empty gap.
                        XCTAssertLessThan(paintedFraction(at: y), 0.1, "Painted gap collapsed at offset \(list.contentOffset.y), row \(a.item), \(style), \(configuration.viewport)")
                        let center = Int((first.frame.midY - list.contentOffset.y).rounded())
                        // The unchanged soft top scroll-edge effect can fade card
                        // pixels near the header; sample the unobscured body.
                        if center > 80, center < cg.height - 12 {
                            XCTAssertGreaterThan(paintedFraction(at: center), 0.5, "Verify rendered body at y \(center), offset \(list.contentOffset.y), row \(a.item), \(style), viewport \(configuration.viewport)")
                        }
                        checkedGaps += 1
                    }
                }
            }
        }
        XCTAssertGreaterThan(checkedGaps, 60)
    }

    func testLandscapeCardsFillTheirSharedPaneDespiteInheritedRailInset() async throws {
        let scene = try XCTUnwrap(UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first)
        let previous = scene.windows.first(where: \.isKeyWindow)
        let window = UIWindow(windowScene: scene)
        let parent = UIViewController()
        parent.additionalSafeAreaInsets.right = 84
        window.rootViewController = parent; window.makeKeyAndVisible()
        defer { window.isHidden = true; previous?.makeKeyAndVisible() }
        let controller = CityListReorderViewController()
        parent.addChild(controller); parent.view.addSubview(controller.view)
        controller.didMove(toParent: parent)
        let cities = (0..<8).map { City(name: "Width \($0)", timeZoneID: "UTC", canonicalID: "width-test-\($0)") }
        let list = controller.collectionView
        for style in [CityViewPreference.basic, .compact] {
            for partial in [true, false, true, false] {
                var hinge = DuoHingeState(); hinge.receive(partial ? .partiallyOpen : .fullyOpen)
                let configuration = DuoLayoutConfiguration.resolve(.init(
                    hinge: hinge, bounds: CGRect(x: 0, y: 0, width: 951, height: 669),
                    safeContent: CGRect(x: 0, y: 0, width: 867, height: 635), railOnRight: true,
                    occlusions: [CGRect(x: 867, y: 0, width: 84, height: 124)],
                    divisions: partial ? [CGRect(x: 455.5, y: 0, width: 40, height: 669)] : []))
                let width = configuration.listViewport.width
                XCTAssertEqual(width, 391.5)
                parent.view.layoutIfNeeded()
                // Mount against the parent's right edge so the native rail inset
                // actually reaches this child, rather than stopping outside its frame.
                controller.view.frame = CGRect(x: parent.view.bounds.maxX - width, y: 0, width: width, height: 669)
                controller.prepareDuoLayout(viewport: controller.view.bounds.size)
                controller.apply(cities: cities, selectedInstant: Date(timeIntervalSince1970: 1793250000),
                                 userCurrentLocationItem: nil, cityViewPreference: style,
                                 topInset: 25, bottomInset: 34, cardBackgroundColor: Color(uiColor: .magenta))
                list.setContentOffset(.zero, animated: false)
                controller.view.setNeedsLayout(); controller.view.layoutIfNeeded()
                try await Task.sleep(for: .milliseconds(100))
                list.layoutIfNeeded()
                XCTAssertTrue(controller.collectionView === list)
                XCTAssertGreaterThan(list.safeAreaInsets.right, 0)
                let cell = try XCTUnwrap(list.cellForItem(at: IndexPath(item: 0, section: 0)))
                let tolerance: CGFloat = 1 / window.traitCollection.displayScale
                XCTAssertEqual(cell.frame.minX, 8, accuracy: tolerance)
                XCTAssertEqual(list.bounds.width - cell.frame.maxX, 8, accuracy: tolerance)
                XCTAssertEqual(cell.frame.width, width - 16, accuracy: tolerance)
                XCTAssertEqual(cell.frame.height, style == .basic ? 140 : 88, accuracy: tolerance)
                XCTAssertEqual(cell.frame.minY, 64, accuracy: tolerance)
                list.setContentOffset(CGPoint(x: 0, y: 300), animated: false)
                list.layoutIfNeeded()
                XCTAssertGreaterThan(list.contentOffset.y, 0)
                XCTAssertFalse(list.visibleCells.isEmpty)
            }
        }
    }

    func testCellSafeAreaPolicyFollowsPresentationWithoutReplacingTheList() async throws {
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 466, height: 678))
        let parent = UIViewController()
        parent.additionalSafeAreaInsets.bottom = 34
        window.rootViewController = parent
        window.isHidden = false
        defer { window.isHidden = true }
        let controller = CityListReorderViewController()
        parent.addChild(controller)
        parent.view.addSubview(controller.view)
        controller.view.frame = CGRect(x: 0, y: 0, width: 340, height: 669)
        controller.didMove(toParent: parent)
        let list = controller.collectionView
        let cities = (0..<6).map { City(name: "City \($0)", timeZoneID: "UTC", canonicalID: "mode-test-\($0)") }
        // Positive Duo presentation, including repeated folding states. A nil
        // viewport exercises the conventional policy at the same cell geometry.
        let presentations: [CGSize?] = [nil, CGSize(width: 382, height: 678),
            CGSize(width: 455.667, height: 669), CGSize(width: 340, height: 669),
            CGSize(width: 455.667, height: 669), CGSize(width: 382, height: 678),
            CGSize(width: 340, height: 669), CGSize(width: 382, height: 678), nil]
        for viewport in presentations {
            controller.prepareDuoLayout(viewport: viewport)
            controller.apply(cities: cities, selectedInstant: Date(), userCurrentLocationItem: nil,
                             cityViewPreference: .basic, topInset: 25, bottomInset: 34, cardBackgroundColor: .white)
            list.setContentOffset(.zero, animated: false)
            controller.view.layoutIfNeeded()
            try await Task.sleep(for: .milliseconds(50))
            XCTAssertTrue(controller.collectionView === list)
            let edgePath = try XCTUnwrap(list.indexPathsForVisibleItems.max())
            let edgeCell = try XCTUnwrap(list.cellForItem(at: edgePath) as? CityListReorderCollectionCell)
            if viewport != nil {
                XCTAssertEqual(edgeCell.safeAreaInsets, .zero)
                XCTAssertEqual(edgeCell.contentView.safeAreaInsets, .zero)
            } else {
                // UIKit can legitimately return zero for automatically inset
                // conventional cells. Verify that the Duo override is inactive.
                XCTAssertFalse(edgeCell.usesResolvedPaneSafeArea)
                XCTAssertEqual(edgeCell.contentView.safeAreaInsets, edgeCell.safeAreaInsets)
            }
        }
    }
}
