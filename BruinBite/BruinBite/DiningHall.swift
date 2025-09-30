import Foundation
import CoreLocation

public enum LocationType: String, Codable, Hashable {
    case residential
    case campusRetail
}

public struct MealHours: Codable, Hashable {
    public var breakfast: String?
    public var lunch: String?
    public var dinner: String?
    public var lateNight: String?
}

public struct DiningHall: Identifiable, Hashable, Codable {
    public let id: String
    public let name: String
    public let type: LocationType
    public let coordinate: GeoPoint?   // add coords so we can compute distance
    public var hours: MealHours?
}
