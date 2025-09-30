import Foundation

public struct LibraryLocation: Identifiable, Hashable {
    public let id: String
    public let name: String
    public let hours: [LibraryHours]
    public let coordinate: GeoPoint?
    
    public init(id: String, name: String, hours: [LibraryHours] = [], coordinate: GeoPoint?) {
        self.id = id
        self.name = name
        self.hours = hours
        self.coordinate = coordinate
    }
    
    // Hashable conformance
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    // Equatable conformance
    public static func == (lhs: LibraryLocation, rhs: LibraryLocation) -> Bool {
        lhs.id == rhs.id && 
        lhs.name == rhs.name && 
        lhs.hours == rhs.hours && 
        lhs.coordinate == rhs.coordinate
    }
}

public struct LibraryHours: Hashable {
    public let day: String
    public let open: String
    public let close: String
    
    public init(day: String, open: String, close: String) {
        self.day = day
        self.open = open
        self.close = close
    }
}
