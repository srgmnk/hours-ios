
import Foundation

struct FakeResultType: OptionSet { let rawValue: Int; static let address = Self(rawValue: 1) }
@MainActor protocol MKLocalSearchCompleterDelegate: AnyObject {
    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter)
    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: any Error)
}
@MainActor final class MKLocalSearchCompleter: NSObject {
    static var started: [MKLocalSearchCompleter] = []
    weak var delegate: (any MKLocalSearchCompleterDelegate)?
    // Capture the recipient to emulate a callback already queued before delegate removal.
    var queuedDelegate: (any MKLocalSearchCompleterDelegate)?
    var resultTypes: FakeResultType = []
    var results: [MKLocalSearchCompletion] = []
    var cancelCount = 0
    var queryFragment = "" { didSet { queuedDelegate = delegate; Self.started.append(self) } }
    func cancel() { cancelCount += 1 }
    func emit(_ values: [String]) {
        results = values.map { MKLocalSearchCompletion(title: $0) }
        queuedDelegate?.completerDidUpdateResults(self)
    }
    func fail() { queuedDelegate?.completer(self, didFailWithError: CancellationError()) }
}
struct MKLocalSearchCompletion { let title: String }
struct FakeCoordinate { var latitude = 1.0; var longitude = 1.0 }
func CLLocationCoordinate2DIsValid(_ c: FakeCoordinate) -> Bool { c.latitude.isFinite && c.longitude.isFinite && abs(c.latitude) <= 90 && abs(c.longitude) <= 180 }
struct FakeLocation { var coordinate = FakeCoordinate() }
struct FakeAddress { var shortAddress: String?; var fullAddress: String? }
struct FakeRepresentations {
    enum Style { case full }
    var cityName: String?
    var region: Locale.Region? = nil
    var fullContext: String? = nil
    var regionName: String?
    var cityWithContext: String? { cityName }
    func cityWithContext(_ style: Style) -> String? { fullContext ?? regionName }
}
struct FakeIdentifier: Hashable { var rawValue: String }
struct MKMapItem {
    var identifier: FakeIdentifier? = nil
    var alternateIdentifiers: Set<FakeIdentifier> = []
    var name: String? = nil
    var pointOfInterestCategory: FakeIdentifier? = nil
    var location = FakeLocation()
    var timeZone: TimeZone? = TimeZone(identifier: "America/New_York")
    var address: FakeAddress? = nil
    var addressRepresentations: FakeRepresentations?
    init(_ city: String, country: String = "United States", zone: String = "America/New_York") {
        addressRepresentations = FakeRepresentations(cityName: city, regionName: country)
        timeZone = TimeZone(identifier: zone)
    }
}
@MainActor final class MKLocalSearch {
    final class Request {
        var naturalLanguageQuery: String?
        var resultTypes: FakeResultType = []
        init() {}
        init(completion: MKLocalSearchCompletion) { naturalLanguageQuery = completion.title }
    }
    struct Response { var mapItems: [MKMapItem] }
    static var started: [MKLocalSearch] = []
    let request: Request
    var cancelCount = 0
    var responseCount = 0
    var continuation: CheckedContinuation<Response, any Error>?
    init(request: Request) { self.request = request }
    func start() async throws -> Response {
        try await withCheckedThrowingContinuation { continuation in
            self.continuation = continuation
            Self.started.append(self)
        }
    }
    func cancel() {
        cancelCount += 1
        guard let continuation else { return }
        self.continuation = nil
        continuation.resume(throwing: CancellationError())
    }
    func complete(_ items: [MKMapItem]) {
        guard let continuation else { return }
        self.continuation = nil
        responseCount += 1
        continuation.resume(returning: Response(mapItems: items))
    }
    func fail() {
        guard let continuation else { return }
        self.continuation = nil
        continuation.resume(throwing: CocoaError(.fileReadUnknown))
    }
}
