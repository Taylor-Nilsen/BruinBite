import Foundation

final class LibraryDataService {
    
    private static let libraryCoords: [String: GeoPoint] = [
        "powell": GeoPoint(lat: 34.07192, lon: -118.44218),
        "youngresearch": GeoPoint(lat: 34.07460, lon: -118.44135),
        "biomed": GeoPoint(lat: 34.06676, lon: -118.44236),
        "music": GeoPoint(lat: 34.07103, lon: -118.44045),
        "arts": GeoPoint(lat: 34.07430, lon: -118.43934),
        "management": GeoPoint(lat: 34.07429, lon: -118.44362),
        "sel": GeoPoint(lat: 34.06923, lon: -118.44256),
        "eastasian": GeoPoint(lat: 34.07473, lon: -118.44191),
        "lawlib": GeoPoint(lat: 34.07290, lon: -118.43827)
    ]

    func fetchLibraries() async throws -> [LibraryLocation] {
        // Return static library data without scraping
        let libraries = Self.libraryCoords.map { (id, coord) in
            return LibraryLocation(
                id: id,
                name: nameForLibraryID(id),
                hours: [], // No hours data
                coordinate: coord
            )
        }
        
        return libraries
    }
    
    private func nameForLibraryID(_ id: String) -> String {
        switch id {
        case "powell": return "Powell Library"
        case "youngresearch": return "Charles E. Young Research Library"
        case "biomed": return "Biomedical Library"
        case "music": return "Music Library"
        case "arts": return "Arts Library"
        case "management": return "Management Library"
        case "sel": return "Science and Engineering Library"
        case "eastasian": return "East Asian Library"
        case "lawlib": return "Law Library"
        default: return id.capitalized
        }
    }
}