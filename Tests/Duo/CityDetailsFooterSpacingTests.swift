import XCTest
import SwiftUI
@testable import MapHarness

@MainActor final class CityDetailsFooterSpacingTests: XCTestCase {
    private let innerLandscape = CGSize(width: 951, height: 669)

    func testTwentyPointScopeIncludesClosedDuoAndInnerLandscape() {
        let cases: [(String, DuoHingeState.Status, CGSize, CGSize, Bool)] = [
            ("outer landscape", .closed, .init(width: 678, height: 466), .init(width: 678, height: 466), true),
            ("partial landscape", .partiallyOpen, innerLandscape, innerLandscape, true),
            ("full landscape", .fullyOpen, innerLandscape, innerLandscape, true),
            ("left split", .fullyOpen, .init(width: 469, height: 669), innerLandscape, true),
            ("right split", .fullyOpen, .init(width: 469, height: 669), innerLandscape, true),
            ("partial portrait", .partiallyOpen, .init(width: 669, height: 951), .init(width: 669, height: 951), false),
            ("full portrait", .fullyOpen, .init(width: 669, height: 951), .init(width: 669, height: 951), false),
            ("outer portrait", .closed, .init(width: 466, height: 678), .init(width: 466, height: 678), true),
            ("phone landscape", .unavailable, .init(width: 874, height: 402), .init(width: 874, height: 402), false),
            ("phone portrait", .unavailable, .init(width: 402, height: 874), .init(width: 402, height: 874), false)
        ]
        for (name, hinge, window, screen, expected) in cases {
            let layout = CityDetailsLayoutObserver.configuration(hinge: hinge, window: window, screen: screen)
            XCTAssertEqual(layout.usesTwentyPointFooterSpacing, expected, name)
            XCTAssertEqual(layout.usesWideSummary, name == "full landscape", name)
        }
    }

    func testSummaryAllocationAndUnchangedNonLandscapeSpacing() {
        for safeBottom: CGFloat in [0, 21, 24, 34, 56] {
            let original = CityDetailsFooterSpacing(usesTwentyPointGaps: false, safeAreaBottom: safeBottom)
            XCTAssertEqual(original.top, 32)
            XCTAssertEqual(original.bottom, safeBottom - 32)
            XCTAssertEqual(original.summaryBottom, 0)
            let landscape = CityDetailsFooterSpacing(usesTwentyPointGaps: true, safeAreaBottom: safeBottom)
            XCTAssertEqual(landscape.top, 20)
            XCTAssertEqual(landscape.bottom + safeBottom, 20)
            // The changed info height is absorbed below the summary, keeping
            // its illustration, text and flexible spacers at their old positions.
            XCTAssertEqual(landscape.summaryBottom + landscape.top + landscape.bottom,
                           original.top + original.bottom)
        }
    }

    private func render<V: View>(_ view: V, width: CGFloat) throws -> UIImage {
        let renderer = ImageRenderer(content: view)
        renderer.proposedSize = .init(width: width, height: nil)
        renderer.scale = 3
        return try XCTUnwrap(renderer.uiImage)
    }

    private func rgba(_ image: CGImage) -> [UInt8] {
        var pixels = [UInt8](repeating: 0, count: image.width * image.height * 4)
        pixels.withUnsafeMutableBytes { bytes in
            let context = CGContext(data: bytes.baseAddress, width: image.width, height: image.height,
                                    bitsPerComponent: 8, bytesPerRow: image.width * 4,
                                    space: CGColorSpaceCreateDeviceRGB(),
                                    bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
            context.draw(image, in: CGRect(x: 0, y: 0, width: image.width, height: image.height))
        }
        return pixels
    }

    func testRenderedGapsAndCardGeometryAtLandscapeAndNarrowWidths() throws {
        let city = City(name: "London", timeZoneID: "Europe/London")
        let details = CityDetailsView(
            weatherCardState: .loaded(.init(title: "Clear", value: "8°C", secondary: "Feels like 4°C", symbolName: "sun.max.fill")),
            sunCardState: .loaded(.init(title: "Sunset", value: "16:16", secondary: "Sunrise at 07:14", symbolName: "sunset.fill")),
            city: city, primaryCity: city, date: Date(timeIntervalSince1970: 1794484200),
            relativeOffsetMinutes: 325, cityViewPreference: .basic)
        for width: CGFloat in [256, 338, 402, 450, 453, 466, 469, 605, 652] {
            for dark in [false, true] {
                for type in [DynamicTypeSize.large, .accessibility5] {
                    let theme: AppTheme = dark ? .dark : .light
                    let background = SheetStyle.appScreenBackground(for: theme)
                    let footer = try render(details.bottomLine
                        .environment(\.appTheme, theme).environment(\.dynamicTypeSize, type)
                        .background(background), width: width - 64)
                    var cards: [Data] = []
                    var footerRows: [[UInt8]] = []
                    for landscape in [false, true] {
                        let spacing = CityDetailsFooterSpacing(usesTwentyPointGaps: landscape, safeAreaBottom: 34)
                        let image = try render(details.infoBlock(bottomPadding: spacing.bottom, topSpacing: spacing.top)
                            // Model the physical area below GeometryReader's safe bounds.
                            .padding(.bottom, 34)
                            .environment(\.appTheme, theme).environment(\.dynamicTypeSize, type)
                            .background(background), width: width)
                        let bottomGap = image.size.height - 157 - spacing.top - footer.size.height
                        XCTAssertEqual(bottomGap, landscape ? 20 : 36, accuracy: 1 / 3, "width \(width), \(type)")
                        let pixels = try XCTUnwrap(image.cgImage)
                        let cardCrop = try XCTUnwrap(pixels.cropping(to: CGRect(x: 0, y: 0, width: width * 3, height: 157 * 3)))
                        cards.append(try XCTUnwrap(UIImage(cgImage: cardCrop).pngData()))
                        // Compare the actual footer pixels at the expected content
                        // origin, rather than treating a padded frame as the row.
                        let row = try XCTUnwrap(pixels.cropping(to: CGRect(x: 32 * 3, y: (157 + spacing.top) * 3,
                                                                          width: (width - 64) * 3, height: footer.size.height * 3)))
                        footerRows.append(rgba(row))
                        if type == .large {
                            let attachment = XCTAttachment(image: image)
                            attachment.name = "footer-\(landscape ? "after" : "before")-\(Int(width))-\(dark ? "dark" : "light")"
                            attachment.lifetime = .keepAlways
                            add(attachment)
                        }
                    }
                    XCTAssertEqual(cards[0], cards[1], "Weather cards must retain identical pixels")
                    XCTAssertEqual(footerRows[0].count, footerRows[1].count)
                    let differences = zip(footerRows[0], footerRows[1]).map { abs(Int($0) - Int($1)) }
                    XCTAssertLessThanOrEqual(differences.max() ?? 0, 2,
                        "Footer pixels must translate from the 32 pt gap to the 20 pt gap, allowing color rounding")
                }
            }
        }
    }
}
