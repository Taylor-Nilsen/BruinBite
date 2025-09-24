import Foundation
import CoreLocation

public struct GeoPoint: Codable, Hashable {
    public let lat: Double
    public let lon: Double
}
