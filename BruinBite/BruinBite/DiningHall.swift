import Foundation
import CoreLocation

public enum LocationType: String, Codable, Hashable {
    case residential
    case campusRetail
}

public struct DiningHall: Identifiable, Hashable, Codable {
    public let id: String
    public let name: String
    public let url: URL?
    public let type: LocationType
    public let coordinate: GeoPoint?   // add coords so we can compute distance
}
