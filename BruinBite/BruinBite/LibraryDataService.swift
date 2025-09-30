import Foundation
import SwiftSoup

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
        let hours = try await fetchHours()
        let libraries = Self.libraryCoords.map { (id, coord) in
            return LibraryLocation(
                id: id,
                name: nameForLibraryID(id),
                services: hours[id] ?? [],
                coordinate: coord
            )
        }
        
        return libraries
    }
    
    private func fetchHours() async throws -> [String: [LibraryService]] {
        let url = URL(string: "https://calendar.library.ucla.edu/hours")!
        let (data, _) = try await URLSession.shared.data(from: url)
        guard let html = String(data: data, encoding: .utf8) else {
            throw NSError(domain: "LibraryDataService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to decode HTML"])
        }
        
        guard let doc = try? SwiftSoup.parse(html) else { return [:] }
        
        var result: [String: [LibraryService]] = [:]
        
        // Find the td for September 29
        guard let dayHeaders = try? doc.select(".s-lc-hm-day-l") else { return [:] }
        var dayTd: Element? = nil
        for header in dayHeaders {
            if (try? header.text()) == "29" {
                dayTd = header.parent()
                break
            }
        }
        guard let dayTd = dayTd else { return [:] }
        
        if let locations = try? dayTd.select(".s-lc-hm-loc") {
            for loc in locations {
            let nameElement = try? loc.select(".loc_name").first()
            let name = try? nameElement?.text() ?? ""
            if name?.isEmpty == true { continue }
            
            let isSub = loc.hasClass("s-lc-hm-subloc")
            
            let timeElement = try? loc.select(".s-lc-time, .s-lc-closed, .s-lc-allday").first()
            let timeText = try? timeElement?.text() ?? ""
            let isClosed = timeElement?.hasClass("s-lc-closed") ?? false
            var time = isClosed ? "Closed" : timeText
            
            if time?.isEmpty == true { continue }
            
            if isSub {
                if time == "-" { continue }
            } else {
                if time == "-" { time = "Closed" }
            }
            
            var libraryName = name ?? ""
            if isSub {
                libraryName = (try? loc.parent()?.select(".loc_name").first()?.text()) ?? libraryName
            }
            
            let id = mapNameToId(libraryName)
            if id.isEmpty { continue }
            
            if !result.keys.contains(id) {
                result[id] = []
            }
            
            if isSub && (name ?? "") == "Hours" { continue }
            
            if !isSub && result[id]!.contains(where: { $0.name == "Library" }) { continue }
            
            let serviceName = isSub ? cleanName(name ?? "") : "Library"
            
            if serviceName == "Library" && result[id]!.contains(where: { $0.name == "Library" }) { continue }
            
            result[id]!.append(LibraryService(name: serviceName, time: time ?? ""))
        }
        }
        
        // Remove duplicates
        for (id, services) in result {
            result[id] = Array(Set(services))
        }
        
        return result
    }
    
    private func cleanName(_ name: String) -> String {
        if let openParen = name.firstIndex(of: "("),
           let closeParen = name.firstIndex(of: ")"),
           openParen < closeParen {
            let beforeParen = name[..<openParen]
            return String(beforeParen).trimmingCharacters(in: .whitespaces)
        }
        return name
    }
    
    private func mapNameToId(_ name: String) -> String {
        switch name {
        case "Powell Library": return "powell"
        case "Research Library (Charles E. Young)": return "youngresearch"
        case "Biomedical Library": return "biomed"
        case "Music Library": return "music"
        case "Arts Library": return "arts"
        case "Rosenfeld Management Library": return "management"
        case "SEL/Boelter": return "sel"
        case "East Asian Library": return "eastasian"
        case "Law Library": return "lawlib"
        default: return name.lowercased().replacingOccurrences(of: " ", with: "")
        }
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