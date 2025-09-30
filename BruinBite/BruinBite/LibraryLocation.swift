import Foundation

public struct LibraryLocation: Identifiable, Hashable {
    public let id: String
    public let name: String
    public var services: [LibraryService]
    public let coordinate: GeoPoint?
    
    public init(id: String, name: String, services: [LibraryService] = [], coordinate: GeoPoint?) {
        self.id = id
        self.name = name
        self.services = services
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
        lhs.services == rhs.services && 
        lhs.coordinate == rhs.coordinate
    }
}

public struct LibraryService: Hashable {
    public let name: String
    public let time: String
    
    public init(name: String, time: String) {
        self.name = name
        self.time = time
    }
}
