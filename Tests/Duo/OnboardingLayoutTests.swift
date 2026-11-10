import XCTest
import SwiftUI
@testable import MapHarness

@MainActor final class OnboardingLayoutTests: XCTestCase {
    private func input(_ size: CGSize, status: DuoHingeState.Status = .fullyOpen,
                       right: Bool? = true, side: CGFloat = 80, bottom: CGFloat = 24) -> DuoLayoutConfiguration.Input {
        var hinge = DuoHingeState(); hinge.receive(status)
        let portrait = size == CGSize(width: 669, height: 951)
        let safe = portrait ? CGRect(x: 0, y: 84, width: size.width, height: size.height - 84 - bottom) :
            CGRect(x: 0, y: 0, width: size.width - side, height: size.height - bottom)
        return .init(hinge: hinge, bounds: CGRect(origin: .zero, size: size), safeContent: safe,
                     railOnRight: right, occlusions: [], divisions: [])
    }

    func testFigmaOuterMeasurements() throws {
        let c = try XCTUnwrap(DuoOnboardingLayout.resolve(input(.init(width: 466, height: 678), status: .closed)))
        XCTAssertEqual(c.arrangement, .outer)
        XCTAssertEqual(c.artwork, CGRect(x: -102, y: 159, width: 589.5, height: 507.5))
        XCTAssertEqual(c.headline1Center, CGPoint(x: 196.5, y: 129))
        XCTAssertEqual(c.headline2Center, CGPoint(x: 195, y: 213))
        XCTAssertEqual(c.button, CGRect(x: 24, y: 590, width: 338, height: 64))
    }

    func testFigmaLandscapeMeasurements() throws {
        let c = try XCTUnwrap(DuoOnboardingLayout.resolve(input(.init(width: 951, height: 669))))
        XCTAssertEqual(c.arrangement, .landscape)
        XCTAssertEqual(c.artwork, CGRect(x: -55, y: 81, width: 589.5, height: 507.5))
        XCTAssertEqual(c.headline1Center, CGPoint(x: 675.5, y: 272.5))
        XCTAssertEqual(c.headline2Center, CGPoint(x: 675.5, y: 372.5))
        XCTAssertEqual(c.button, CGRect(x: 488, y: 581, width: 375, height: 64))
        XCTAssertEqual(c.logo.minX, 654.4130859375, accuracy: 0.001)
        XCTAssertEqual(c.logo.minY, 25)
    }

    func testFigmaPortraitMeasurements() throws {
        let c = try XCTUnwrap(DuoOnboardingLayout.resolve(input(.init(width: 669, height: 951), right: nil)))
        XCTAssertEqual(c.arrangement, .portrait)
        XCTAssertEqual(c.artwork, CGRect(x: 39.75, y: 24.25, width: 589.5, height: 507.5))
        XCTAssertEqual(c.artworkClip, CGRect(x: 0, y: 0, width: 669, height: 476))
        XCTAssertEqual(c.logo.origin, CGPoint(x: 302, y: 34))
        XCTAssertEqual(c.headline1Center, CGPoint(x: 334.5, y: 593.5))
        XCTAssertEqual(c.headline2Center, CGPoint(x: 334.5, y: 693.5))
        XCTAssertEqual(c.button, CGRect(x: 112, y: 863, width: 445, height: 64))
    }

    func testFigmaSplitLeftAndSafeSplitRight() throws {
        let left = input(.init(width: 470, height: 669), right: false, side: 0)
        let c = try XCTUnwrap(DuoOnboardingLayout.resolve(left))
        XCTAssertEqual(c.arrangement, .compact)
        XCTAssertEqual(c.artwork, CGRect(x: -60, y: 159, width: 589.5, height: 507.5))
        XCTAssertEqual(c.headline1Center, CGPoint(x: 234.5, y: 129))
        XCTAssertEqual(c.headline2Center, CGPoint(x: 235, y: 213))
        XCTAssertEqual(c.button, CGRect(x: 66, y: 581, width: 338, height: 64))
        let right = input(.init(width: 469, height: 669), side: 84, bottom: 34)
        let r = try XCTUnwrap(DuoOnboardingLayout.resolve(right))
        XCTAssertEqual(r.arrangement, .compact)
        XCTAssertEqual(r.artwork.size, c.artwork.size)
        XCTAssertTrue(right.safeContent.contains(r.button))
        XCTAssertTrue(right.safeContent.contains(r.logo))
        XCTAssertEqual(r.headline2Center.x, right.safeContent.midX)
    }

    func testEquivalentPosturesAndTransientHingeDoNotChangeFrames() throws {
        for size in [CGSize(width: 951, height: 669), CGSize(width: 669, height: 951), CGSize(width: 469, height: 669)] {
            var i = input(size, right: size.width == 669 ? nil : true, side: 84, bottom: 34)
            let full = try XCTUnwrap(DuoOnboardingLayout.resolve(i))
            for status: DuoHingeState.Status in [.partiallyOpen, .fullyOpen, .unavailable, .partiallyOpen] {
                i.hinge.receive(status)
                if size.width == 951 { i.divisions = [CGRect(x: 455.5, y: 0, width: 40, height: 669)] }
                if size.width == 669 { i.divisions = [CGRect(x: 0, y: 455.5, width: 669, height: 40)] }
                XCTAssertEqual(DuoOnboardingLayout.resolve(i), full)
            }
        }
    }

    func testConventionalGeometryNeverEstablishesDuoCapability() {
        for size in [CGSize(width: 393, height: 852), CGSize(width: 440, height: 956),
                     CGSize(width: 951, height: 669), CGSize(width: 669, height: 951)] {
            var i = input(size)
            i.hinge = DuoHingeState()
            XCTAssertNil(DuoOnboardingLayout.resolve(i))
        }
    }

    func testWindowResizingAndNativeBottomClearance() throws {
        for width: CGFloat in [320, 382, 466, 469, 470, 600, 951] {
            let i = input(.init(width: width, height: 669), side: width == 470 ? 0 : 84, bottom: 34)
            let c = try XCTUnwrap(DuoOnboardingLayout.resolve(i))
            XCTAssertTrue(i.safeContent.contains(c.button))
            XCTAssertTrue(i.safeContent.contains(c.logo))
            XCTAssertEqual(c.button.maxY, i.safeContent.maxY)
            XCTAssertEqual(c.artwork.width / c.artwork.height, 589.5 / 507.5, accuracy: 0.00001)
        }
    }

    func testBothStepsKeepOriginalCopyAndAssets() {
        XCTAssertEqual(OnboardingStep.allCases.count, 2)
        XCTAssertEqual(OnboardingStep.step1.headline1, "Find and add a city\nor time zone")
        XCTAssertEqual(OnboardingStep.step1.headline2, "Rename them\nif you want")
        XCTAssertEqual(OnboardingStep.step2.headline1, "Spin the dial to move\nthrough time")
        XCTAssertEqual(OnboardingStep.step2.headline2, "Add a widget to your\nlock screen")
        XCTAssertEqual(OnboardingStep.step1.buttonTitle, "Next up")
        XCTAssertEqual(OnboardingStep.step2.buttonTitle, "Jump up")
        for step in OnboardingStep.allCases {
            for name in [step.backImageName, step.middleImageName, step.frontImageName] {
                for style in [UIUserInterfaceStyle.light, .dark] {
                    let image = UIImage(named: name, in: .main, compatibleWith: UITraitCollection(userInterfaceStyle: style))
                    XCTAssertNotNil(image, "Missing \(name), \(style)")
                }
            }
        }
    }
}
