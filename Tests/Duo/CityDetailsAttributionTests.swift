import XCTest
import SwiftUI
import Vision
@testable import MapHarness

@MainActor final class CityDetailsAttributionTests: XCTestCase {
    private func details(offset: Int = 0, zone: String = "Asia/Bangkok") -> CityDetailsView {
        let city = City(name: "Fixture", timeZoneID: zone)
        return CityDetailsView(city: city, primaryCity: city,
                               date: Date(timeIntervalSince1970: 1783339200),
                               relativeOffsetMinutes: offset, cityViewPreference: .basic)
    }

    func testFooterFitsThemesWidthsAndDynamicType() throws {
        // Available footer widths after the unchanged 32pt side padding:
        // narrow, conventional, Duo outer, inner portrait/partial and landscape.
        for width: CGFloat in [200, 256, 311, 338, 402, 469, 605, 887] {
            for dark in [false, true] {
                for size in [DynamicTypeSize.large, .accessibility3, .accessibility5] {
                    let content = details(offset: width == 256 ? 345 : 0).bottomLine
                        .environment(\.appTheme, dark ? .dark : .light)
                        .environment(\.colorScheme, dark ? .dark : .light)
                        .environment(\.dynamicTypeSize, size)
                        .frame(width: width)
                        .padding(4)
                        .background(dark ? Color.black : Color.white)
                    let renderer = ImageRenderer(content: content)
                    renderer.scale = 2
                    let image = try XCTUnwrap(renderer.uiImage)
                    XCTAssertEqual(image.size.width, width + 8, accuracy: 0.5)
                    XCTAssertGreaterThan(image.size.height, 15)
                    if size.isAccessibilitySize {
                        XCTAssertGreaterThan(image.size.height, 30, "Footer must grow rather than shrink accessible text")
                    }
                    // Retain representative renders for visual clipping/overlap review.
                    if width == 200 || width == 338 || width == 605 {
                        let attachment = XCTAttachment(image: image)
                        attachment.name = "footer-\(Int(width))-\(dark ? "dark" : "light")-\(size)"
                        attachment.lifetime = .keepAlways; add(attachment)
                    }
                }
            }
        }
    }

    func testDefaultFooterShowsCompleteCreditLeftAndUTCRight() throws {
        let renderer = ImageRenderer(content: details().bottomLine
            .environment(\.appTheme, .light).frame(width: 338).padding(8).background(.white))
        renderer.scale = 3
        let image = try XCTUnwrap(renderer.cgImage)
        let request = VNRecognizeTextRequest()
        request.recognitionLevel = .accurate
        try VNImageRequestHandler(cgImage: image).perform([request])
        let observations = request.results ?? []
        let strings = observations.compactMap { $0.topCandidates(1).first?.string }
        XCTAssertTrue(strings.joined(separator: " ").contains("Data by Open-Meteo.com"), strings.description)
        XCTAssertTrue(strings.joined(separator: " ").contains("UTC+7"), strings.description)
    }

    func testRelativeDeltaIsAbsentAndDSTRemainsPresent() throws {
        let renderer = ImageRenderer(content: details(offset: 345, zone: "Europe/London").bottomLine
            .environment(\.appTheme, .light).frame(width: 605).padding(8).background(.white))
        renderer.scale = 3
        let image = try XCTUnwrap(renderer.cgImage)
        let request = VNRecognizeTextRequest(); request.recognitionLevel = .accurate
        try VNImageRequestHandler(cgImage: image).perform([request])
        let text = (request.results ?? []).compactMap { $0.topCandidates(1).first?.string }.joined(separator: " ")
        XCTAssertFalse(text.contains("from now"), text)
        XCTAssertFalse(text.contains("5:45"), text)
        XCTAssertTrue(text.contains("UTC+1"), text)
        XCTAssertTrue(text.contains("DST"), text)
    }
}
