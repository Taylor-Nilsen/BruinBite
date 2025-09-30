import Foundation
import CoreLocation

public enum LocationType: String, Codable, Hashable {
    case residential
    case campusRetail
}

public struct MealHours: Codable, Hashable {
    public let breakfast: String?
    public let lunch: String?
    public let dinner: String?
    public let lateNight: String?
}

public struct DiningHall: Identifiable, Hashable, Codable {
    public let id: String
    public let name: String
    public let type: LocationType
    public let coordinate: GeoPoint?   // add coords so we can compute distance
    public var hours: MealHours?
}
