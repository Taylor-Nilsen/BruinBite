import Foundation

public struct GymLocation: Identifiable, Hashable {
    public let id: String
    public let name: String
    public let hours: [GymHours]
    public let coordinate: GeoPoint?
}

public struct GymHours: Hashable {
    public let day: String // e.g. "Monday"
    public let open: String // e.g. "06:00"
    public let close: String // e.g. "22:00"
}
