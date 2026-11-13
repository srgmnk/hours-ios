import XCTest
import SwiftUI
import Vision
@testable import MapHarness

@MainActor final class CityDetailsLayoutTests: XCTestCase {
    private func details(wide: Bool, date: String = "2026-11-12T11:50:00Z", name: String = "London", summaryOffset: CGFloat = 0) -> CityDetailsView {
        CityDetailsView(
            weatherCardState: .loaded(.init(title: "Clear", value: "8°C", secondary: "Feels like 4°C", symbolName: "sun.max.fill")),
            sunCardState: .loaded(.init(title: "Sunset", value: "16:16", secondary: "Sunrise at 07:14", symbolName: "sunset.fill")),
            layout: .init(usesWideSummary: wide, summaryVerticalOffset: summaryOffset),
            city: City(name: name, timeZoneID: "Europe/London"),
            primaryCity: City(name: "Bangkok", timeZoneID: "Asia/Bangkok"),
            date: ISO8601DateFormatter().date(from: date)!, relativeOffsetMinutes: 325,
            cityViewPreference: .basic)
    }

    private func render<V: View>(_ view: V, width: CGFloat) throws -> UIImage {
        let renderer = ImageRenderer(content: view)
        renderer.proposedSize = .init(width: width, height: nil)
        renderer.scale = 3
        return try XCTUnwrap(renderer.uiImage)
    }

    private func recognizedLines(_ image: UIImage) throws -> [String] {
        let request = VNRecognizeTextRequest()
        request.recognitionLevel = .accurate
        try VNImageRequestHandler(cgImage: XCTUnwrap(image.cgImage)).perform([request])
        return (request.results ?? []).compactMap { $0.topCandidates(1).first?.string }
    }

    func testOnlyFullyOpenFullWindowLandscapeUsesWideSummary() {
        let landscape = CGSize(width: 951, height: 669)
        for hinge: DuoHingeState.Status in [.unavailable, .closed, .partiallyOpen, .fullyOpen] {
            for window in [landscape, CGSize(width: 669, height: 951), CGSize(width: 466, height: 678), CGSize(width: 469, height: 669), CGSize(width: 951, height: 334)] {
                XCTAssertEqual(CityDetailsLayoutObserver.usesWideSummary(hinge: hinge, window: window, screen: landscape),
                    hinge == .fullyOpen && window == landscape, "\(hinge), \(window)")
            }
        }
    }

    func testSummaryOffsetUsesDisplayOrientationRatherThanNarrowPaneOrientation() {
        for hinge: DuoHingeState.Status in [.unavailable, .closed, .partiallyOpen, .fullyOpen] {
            for screen in [CGSize(width: 951, height: 669), CGSize(width: 669, height: 951),
                           CGSize(width: 678, height: 466), CGSize(width: 466, height: 678)] {
                for window in [screen, CGSize(width: screen.width / 2, height: screen.height)] {
                    let layout = CityDetailsLayoutObserver.configuration(hinge: hinge, window: window, screen: screen)
                    XCTAssertEqual(layout.summaryVerticalOffset,
                                   hinge == .closed || (hinge != .unavailable && screen.width > screen.height) ? 20 : 0,
                                   "\(hinge), window \(window), display \(screen)")
                }
            }
        }
    }

    func testSummaryMovesTwentyPointsWithoutMovingCardsOrFooter() throws {
        for width: CGFloat in [453, 652] {
            for dark in [false, true] {
                var images: [UIImage] = []
                let reference = details(wide: width == 652)
                let infoHeight = try render(reference.infoBlock(bottomPadding: 20, topSpacing: 20), width: width).size.height
                for offset: CGFloat in [0, 20] {
                    let view = details(wide: width == 652, summaryOffset: offset)
                    let image = try render(VStack(spacing: 0) {
                        view.summaryBlock
                        view.infoBlock(bottomPadding: 20, topSpacing: 20)
                    }.frame(width: width, height: 605)
                        .environment(\.appTheme, dark ? .dark : .light)
                        .environment(\.colorScheme, dark ? .dark : .light)
                        .background(SheetStyle.appScreenBackground(for: dark ? .dark : .light)), width: width)
                    images.append(image)
                    let attachment = XCTAttachment(image: image)
                    attachment.name = "summary-offset-\(Int(offset))-\(Int(width))-\(dark ? "dark" : "light")"
                    attachment.lifetime = .keepAlways
                    add(attachment)
                }
                let before = try XCTUnwrap(images[0].cgImage)
                let after = try XCTUnwrap(images[1].cgImage)
                let scale = images[0].scale
                let summaryHeight = (605 - infoHeight) * scale
                func pixels(_ image: CGImage, y: CGFloat, height: CGFloat) throws -> Data {
                    let crop = try XCTUnwrap(image.cropping(to: CGRect(x: 0, y: y, width: CGFloat(image.width), height: height)))
                    return try XCTUnwrap(UIImage(cgImage: crop).pngData())
                }
                XCTAssertEqual(try pixels(before, y: 0, height: summaryHeight - 20 * scale),
                               try pixels(after, y: 20 * scale, height: summaryHeight - 20 * scale),
                               "The entire illustration and text must translate by exactly 20 pt")
                XCTAssertEqual(try pixels(before, y: summaryHeight, height: infoHeight * scale),
                               try pixels(after, y: summaryHeight, height: infoHeight * scale),
                               "The shifted summary must not overlap or move cards and footer")
            }
        }
    }

    func testScreenshotScenarioRendersTwoCompleteLinesPerTextInBothThemesAndTimeFormats() throws {
        let defaults = UserDefaults.standard
        let previous = defaults.object(forKey: "timeFormatPreference")
        defer { defaults.set(previous, forKey: "timeFormatPreference") }
        for format in ["twelveHour", "twentyFourHour"] {
            defaults.set(format, forKey: "timeFormatPreference")
            for dark in [false, true] {
                let view = details(wide: true)
                XCTAssertEqual(view.vibeSummary.lines, ["Fresh morning,", "people are starting their day"])
                XCTAssertEqual(String(view.overlapPresentation.text.characters), "London is -7h behind Bangkok.\nOverlap today 2h, 09:00–11:00 London")
                let image = try render(view.summaryBlock.frame(height: 340)
                    .environment(\.appTheme, dark ? .dark : .light)
                    .environment(\.colorScheme, dark ? .dark : .light)
                    .background(dark ? Color.black : Color.white), width: 652)
                let lines = try recognizedLines(image)
                XCTAssertEqual(lines.count, 4, lines.description)
                XCTAssertTrue(lines.contains("people are starting their day"), lines.description)
                XCTAssertTrue(lines.contains { $0.contains("Overlap today 2h,") && $0.contains("London") }, lines.description)
            }
        }
    }

    func testEveryHeadlinePreservesWordsAndFitsTwoRowsAtApprovedWidth() throws {
        for day in [12, 14, 15] {
            for hour in [1, 7, 10, 14, 18, 22] {
                let date = String(format: "2026-11-%02dT%02d:00:00Z", day, hour)
                let original = details(wide: false, date: date).vibeSummary.lines
                let wide = details(wide: true, date: date).vibeSummary.lines
                XCTAssertEqual(original.count, 3)
                XCTAssertEqual(wide.joined(separator: " "), original.joined(separator: " "))
                for line in wide {
                    let text = Text(line).font(.system(size: 32, weight: .medium)).tracking(-0.96)
                    let natural = try render(text.fixedSize(), width: 596)
                    let constrained = try render(text.fixedSize(horizontal: false, vertical: true), width: 596)
                    XCTAssertEqual(natural.size.height, constrained.size.height, accuracy: 0.5, line)
                    XCTAssertLessThanOrEqual(natural.size.width, 596, line)
                }
            }
        }
    }

    func testLongSupportingTextRemainsCompleteWithoutLineLimit() throws {
        let view = details(wide: true, name: "A deliberately long city name with many additional words")
        let image = try render(view.overlapText.padding(.horizontal, 32).background(.white), width: 652)
        let text = try recognizedLines(image).joined(separator: " ")
        XCTAssertTrue(text.contains("additional words"), text)
        XCTAssertFalse(text.contains("…"), text)
        XCTAssertGreaterThan(image.size.height, 40, "Long names must wrap naturally rather than truncate")
    }

    func testFooterOffsetsAndDeltaIndependence() throws {
        for (zone, expected) in [("Asia/Bangkok", "UTC+7"), ("America/Bogota", "UTC−5"), ("UTC", "UTC+0"), ("Asia/Kolkata", "UTC+5:30"), ("Asia/Kathmandu", "UTC+5:45")] {
            let city = City(name: "Fixture", timeZoneID: zone)
            var images: [Data] = []
            for delta in [-325, 0, 325] {
                let view = CityDetailsView(city: city, primaryCity: city, date: Date(timeIntervalSince1970: 1794484200), relativeOffsetMinutes: delta, cityViewPreference: .basic)
                XCTAssertEqual(view.timeZoneDisplayText, expected)
                let image = try render(view.bottomLine.background(.white), width: 338)
                images.append(try XCTUnwrap(image.pngData()))
                let text = try recognizedLines(image).joined(separator: " ")
                XCTAssertTrue(text.contains("Data by Open-Meteo.com"), text)
                XCTAssertFalse(text.contains("from now"), text)
            }
            XCTAssertEqual(images[0], images[1])
            XCTAssertEqual(images[1], images[2])
        }
    }

    func testCaptureApprovedSummaryAndUnchangedCardGeometry() throws {
        for dark in [false, true] {
            var cardAndFooterPixels: [Data] = []
            for wide in [false, true] {
                let view = details(wide: wide)
                let image = try render(VStack(spacing: 0) {
                    view.summaryBlock
                    view.infoBlock(bottomPadding: 24)
                }.frame(width: 652, height: 605)
                    .environment(\.appTheme, dark ? .dark : .light)
                    .environment(\.colorScheme, dark ? .dark : .light)
                    .background(SheetStyle.appScreenBackground(for: dark ? .dark : .light)), width: 652)
                let attachment = XCTAttachment(image: image)
                attachment.name = "details-\(wide ? "wide" : "original-wrap")-\(dark ? "dark" : "light")"
                attachment.lifetime = .keepAlways
                add(attachment)
                let footerHeight = try render(view.infoBlock(bottomPadding: 24), width: 652).size.height
                let pixels = try XCTUnwrap(image.cgImage)
                let bottom = try XCTUnwrap(pixels.cropping(to: CGRect(x: 0,
                    y: CGFloat(pixels.height) - footerHeight * image.scale,
                    width: CGFloat(pixels.width), height: footerHeight * image.scale)))
                cardAndFooterPixels.append(try XCTUnwrap(UIImage(cgImage: bottom).pngData()))
            }
            XCTAssertEqual(cardAndFooterPixels[0], cardAndFooterPixels[1],
                "Changing summary wrapping must not move or repaint the cards and footer")
        }
    }
}
