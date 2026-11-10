import XCTest
import SwiftUI
@testable import MapHarness

@MainActor final class WorldMapSizingTests: XCTestCase {
    private let instant = Date(timeIntervalSince1970: 1793250000)
    private var cities: [City] {
        [("London", "Europe/London", 51.5074, -0.1278),
         ("Berlin", "Europe/Berlin", 52.52, 13.405),
         ("Bangkok", "Asia/Bangkok", 13.7563, 100.5018),
         ("Delhi", "Asia/Kolkata", 28.6139, 77.209),
         ("Ghaziabad", "Asia/Kolkata", 28.6692, 77.4538)].map {
            City(name: $0.0, timeZoneID: $0.1, canonicalID: "sizing-\($0.0)", latitude: $0.2, longitude: $0.3)
        }
    }
    private let profiles: [(String, WorldMapGeometryProfile, CGSize)] = [
        ("landscape", .duoInner, CGSize(width:527,height:669)),
        ("portrait", .duoInnerPortrait, CGSize(width:669,height:476)),
        ("outer", .duoOuter, CGSize(width:382,height:678)),
        ("iphone", .conventional, CGSize(width:393,height:852)),
        ("partial", .duoInner, CGSize(width:455.667,height:669)),
        ("partial-portrait", .duoInnerPortrait, CGSize(width:669,height:407)),
        ("split", .duoOuter, CGSize(width:375,height:669))]

    func testVisualSizesGroupingRegistrationAndWrapAcrossProfiles() throws {
        let map = WorldMapScrollView(frame:CGRect(x:0,y:0,width:527,height:669))
        map.updatePosition(0.62) { _ in }
        map.updateMarkers(cities, at:instant, timeFormatPreference:"twentyFourHour", localeIdentifier:"en_US")
        var originalDots: [CGSize] = [], originalLabels: [CGSize] = []
        let referenceScale = CGFloat(1022)/1129
        for (name, profile, size) in profiles {
            map.updatePresentation(profile:profile, visible:true); map.frame.size = size; map.layoutIfNeeded()
            let side = map.mapCanvas.bounds.width, oldScale = side/1129
            let dots = map.hitDots.map { $0.bounds.size }
            let labels = map.markers.map { $0.convert($0.defaultLabelBounds,to:map.mapCanvas).size }
            if originalDots.isEmpty { originalDots = dots; originalLabels = labels }
            for i in map.markers.indices {
                let marker = map.markers[i]
                XCTAssertEqual(dots[i].width,12,accuracy:1e-6,name)
                XCTAssertEqual(dots[i].height,originalDots[i].height,accuracy:1e-6,name)
                XCTAssertEqual(labels[i].width,originalLabels[i].width,accuracy:1e-6,name)
                XCTAssertEqual(labels[i].height,originalLabels[i].height,accuracy:1e-6,name)
                XCTAssertEqual(marker.transform.a,referenceScale,accuracy:1e-10)
                let anchor = marker.convert(CGPoint(x:marker.bounds.midX,y:6),to:map)
                XCTAssertEqual(anchor.y,profile.canvas(in:size).top+marker.normalizedPoint.y*side,accuracy:1e-6)
            }
            // Reconstruct the previous Stage 6A reference independently of the new transform.
            let legacy = map.markers.map { m -> WorldMapLabelGrouping.Input in
                let anchor = CGPoint(x:m.normalizedPoint.x*side,y:m.normalizedPoint.y*side)
                let r = m.groupingLabelBounds
                return .init(cityID:m.cityID,name:m.displayName,time:m.displayedTime,
                             dotBounds:CGRect(x:anchor.x-6*oldScale,y:anchor.y-6*oldScale,width:12*oldScale,height:12*oldScale),
                             labelBounds:CGRect(x:anchor.x+(r.minX-m.bounds.midX)*oldScale,
                                                y:anchor.y+(r.minY-6)*oldScale,width:r.width*oldScale,height:r.height*oldScale))
            }
            let expected = WorldMapLabelGrouping.groups(legacy,maximumSpan:40*oldScale,periodWidth:side)
                .map { $0.map { map.markers[$0].cityID } }
            XCTAssertEqual(map.sharedLabels.map(\.cityIDs),expected,name)
            for i in map.hitLabels.indices {
                for j in map.hitLabels.indices where j > i {
                    let a = map.hitLabels[i].bounds
                    let b = WorldMapPeriodic.nearest(map.hitLabels[j].bounds,to:a.midX,period:side)
                    XCTAssertFalse(a.intersects(b), "Unnecessary collision in \(name)")
                }
            }
            let cached = map.placementOffsets
            let center = map.normalizedCenter
            for _ in 0..<20 {
                map.bounds.origin.x += side
                map.scrollViewDidScroll(map); map.layoutIfNeeded()
                XCTAssertEqual(map.normalizedCenter,center,accuracy:0.5/side)
                XCTAssertEqual(map.placementOffsets,cached)
            }
            XCTAssertTrue(map.markerTap.delegate === map.markerTapDelegate)
            let dot = try XCTUnwrap(map.hitDots.first)
            XCTAssertEqual(WorldMapHitTesting.cityIDs(at:CGPoint(x:dot.bounds.midX,y:dot.bounds.midY),dots:map.hitDots,labels:map.hitLabels,period:side),dot.cityIDs)
            for label in map.hitLabels {
                let point = CGPoint(x:label.bounds.midX,y:label.bounds.midY)
                XCTAssertFalse(WorldMapHitTesting.cityIDs(at:point,dots:[],labels:map.hitLabels,period:side).isEmpty)
            }
        }
        let portrait = WorldMapGeometryProfile.duoInnerPortrait.canvas(in:CGSize(width:669,height:476))
        XCTAssertEqual(portrait.side/668,1.10,accuracy:1e-12)
        XCTAssertEqual(portrait.top - (-13),-80)
    }

    func testCaptureMapProfiles() async throws {
        let scene = try XCTUnwrap(UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first)
        let previous = scene.windows.first(where: \.isKeyWindow)
        let window = UIWindow(windowScene:scene); let parent = UIViewController()
        window.rootViewController = parent; window.makeKeyAndVisible()
        defer { window.isHidden = true; previous?.makeKeyAndVisible() }
        let map = WorldMapScrollView(frame:CGRect(x:0,y:0,width:527,height:669)); parent.view.addSubview(map)
        map.updatePosition(0.62) { _ in }
        map.updateNightLights(cities); map.updateIllumination(at:instant)
        map.updateMarkers(cities,at:instant,timeFormatPreference:"twentyFourHour",localeIdentifier:"en_US")
        for dark in [false,true] {
            window.overrideUserInterfaceStyle = dark ? .dark : .light
            for (name,profile,size) in profiles {
                map.updatePresentation(profile:profile,visible:true); map.frame.size = size; map.layoutIfNeeded()
                try await Task.sleep(for:.milliseconds(200))
                let screenshot = UIGraphicsImageRenderer(bounds:map.bounds).image { _ in
                    XCTAssertTrue(map.drawHierarchy(in:map.bounds,afterScreenUpdates:true))
                }
                let a = XCTAttachment(image:screenshot); a.name = "map-\(name)-\(dark ? "dark" : "light")"
                a.lifetime = .keepAlways; add(a)
            }
        }
    }
}
