import Foundation

public enum ServiceStatus: String, Hashable {
    case open
    case closed
    case unknown
}

public struct LibraryServiceInfo: Hashable {
    public let name: String
    public let hours: LibraryHours?
    public let status: ServiceStatus
    
    public init(name: String, hours: LibraryHours? = nil, status: ServiceStatus = .unknown) {
        self.name = name
        self.hours = hours
        self.status = status
    }
    
    // Explicit Hashable conformance
    public func hash(into hasher: inout Hasher) {
        hasher.combine(name)
        hasher.combine(hours)
        hasher.combine(status)
    }
    
    // Explicit Equatable conformance
    public static func == (lhs: LibraryServiceInfo, rhs: LibraryServiceInfo) -> Bool {
        lhs.name == rhs.name &&
        lhs.hours == rhs.hours &&
        lhs.status == rhs.status
    }
}
