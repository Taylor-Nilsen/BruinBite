import Foundation

final class LibraryDataService {
    private let hoursScraper = LibraryHoursScraper.shared
    
    private static let defaultAdditionalServices: [String: [LibraryServiceInfo]] = [
        "powell": [
            LibraryServiceInfo(name: "Night Powell", hours: LibraryHours(day: "Today", open: "22:00", close: "08:00"), status: ServiceStatus.closed),
            LibraryServiceInfo(name: "CLICC Classroom Hub", status: ServiceStatus.closed),
            LibraryServiceInfo(name: "Equipment Lending", status: ServiceStatus.closed)
        ]
    ]

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

    // This will eventually scrape https://www.library.ucla.edu/visit/locations
    // For now, returns mock data
    func fetchLibraries() async throws -> [LibraryLocation] {
        async let schedules = hoursScraper.fetchLibraryHours()
        
        let url = URL(string: "https://www.library.ucla.edu/hours")!
        let (data, response) = try await URLSession.shared.data(from: url)
        guard (response as? HTTPURLResponse)?.statusCode == 200,
              let html = String(data: data, encoding: .utf8) else {
            throw URLError(.badServerResponse)
        }
        
        var libraries = parseLibraries(from: html)
        let scrapedSchedules = try await schedules
        
        if libraries.isEmpty {
            libraries = Self.libraryCoords.map { (id, coord) in
                let additionalServices = scrapedSchedules[id].map { schedule in
                    createServicesFromSchedule(schedule)
                } ?? Self.defaultAdditionalServices[id] ?? []
                
                return LibraryLocation(
                    id: id,
                    name: nameForLibraryID(id),
                    hours: defaultHours(for: id),
                    coordinate: coord,
                    additionalServices: additionalServices
                )
            }
        } else {
            libraries = libraries.map { library in
                if let schedule = scrapedSchedules[library.id] {
                    return LibraryLocation(
                        id: library.id,
                        name: library.name,
                        hours: library.hours,
                        coordinate: library.coordinate,
                        additionalServices: createServicesFromSchedule(schedule)
                    )
                }
                return library
            }
        }
        
        return libraries
    }
    
    private func createServicesFromSchedule(_ schedule: LibrarySchedule) -> [LibraryServiceInfo] {
        var services: [LibraryServiceInfo] = []
        
        if let nightHours = schedule.nightHours {
            let (open, close) = parseHours(nightHours)
            services.append(LibraryServiceInfo(
                name: "Night Powell",
                hours: LibraryHours(day: "Today", open: open, close: close),
                status: ServiceStatus.open
            ))
        }
        
        if let cliccHours = schedule.cliccHours {
            let (open, close) = parseHours(cliccHours)
            services.append(LibraryServiceInfo(
                name: "CLICC Classroom Hub",
                hours: LibraryHours(day: "Today", open: open, close: close),
                status: ServiceStatus.open
            ))
        } else {
            services.append(LibraryServiceInfo(
                name: "CLICC Classroom Hub",
                status: ServiceStatus.closed
            ))
        }
        
        if let equipmentHours = schedule.equipmentHours {
            let (open, close) = parseHours(equipmentHours)
            services.append(LibraryServiceInfo(
                name: "Equipment Lending",
                hours: LibraryHours(day: "Today", open: open, close: close),
                status: ServiceStatus.open
            ))
        }
        
        return services
    }
    
    private func parseHours(_ hoursString: String) -> (open: String, close: String) {
        let components = hoursString.split(separator: "-").map(String.init)
        if components.count == 2 {
            return (
                open: components[0].trimmingCharacters(in: .whitespaces),
                close: components[1].trimmingCharacters(in: .whitespaces)
            )
        }
        return (open: "00:00", close: "00:00")
    }
    
    private func parseLibraries(from html: String) -> [LibraryLocation] {
        var libraries: [LibraryLocation] = []
        
        // Common patterns in the HTML
        let blocks = html.components(separatedBy: "<div class=\"hours-location-wrapper\">")
        
        for block in blocks {
            // Extract library name and ID with more flexible patterns
            let namePatterns = [
                #"<h3[^>]*>([^<]+)</h3>"#,
                #"<h2[^>]*>([^<]+)</h2>"#,
                #"class="library-name"[^>]*>([^<]+)<"#
            ]
            
            let idPatterns = [
                #"library-(\w+)"#,
                #"location-(\w+)"#,
                #"hours-(\w+)"#
            ]
            
            // Try each pattern until we find a match
            var foundName: String?
            var foundId: String?
            
            for pattern in namePatterns {
                if let nameMatch = block.range(of: pattern, options: .regularExpression) {
                    foundName = String(block[nameMatch])
                        .replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
                        .trimmingCharacters(in: .whitespacesAndNewlines)
                    break
                }
            }
            
            for pattern in idPatterns {
                if let idMatch = block.range(of: pattern, options: .regularExpression) {
                    foundId = String(block[idMatch])
                        .components(separatedBy: CharacterSet.letters.inverted)
                        .filter { !$0.isEmpty }
                        .last?
                        .lowercased()
                    break
                }
            }
            
            if let name = foundName, let id = foundId {
                // Extract hours with more flexible pattern matching
                var hours: [LibraryHours] = []
                let daysOfWeek = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]
                
                for day in daysOfWeek {
                    // Look for various time formats
                    let patterns = [
                        "\(day)[^0-9]+(\\d{1,2}:\\d{2}\\s*[AaPp][Mm])[^0-9]+(\\d{1,2}:\\d{2}\\s*[AaPp][Mm])",
                        "\(day)[^0-9]+(\\d{1,2}:\\d{2})[^0-9]+(\\d{1,2}:\\d{2})",
                        "\(day)\\s*:\\s*(\\d{1,2}:\\d{2}\\s*[AaPp][Mm])\\s*-\\s*(\\d{1,2}:\\d{2}\\s*[AaPp][Mm])",
                        "\(day)\\s*\\d{1,2}/\\d{1,2}\\s*(\\d{1,2}:\\d{2}\\s*[AaPp][Mm])\\s*-\\s*(\\d{1,2}:\\d{2}\\s*[AaPp][Mm])"
                    ]
                    
                    for pattern in patterns {
                        if let hoursMatch = block.range(of: pattern, options: .regularExpression) {
                            let hoursStr = String(block[hoursMatch])
                            let components = hoursStr.components(separatedBy: CharacterSet(charactersIn: " -"))
                                .compactMap { $0.trimmingCharacters(in: .whitespaces) }
                                .filter { $0.contains(":") }
                            
                            if components.count >= 2 {
                                let open = normalizeTime(components[0])
                                let close = normalizeTime(components[1])
                                hours.append(LibraryHours(day: day, open: open, close: close))
                                break
                            }
                        }
                    }
                }
                
                // If we found valid hours and have coordinates, add the library
                if !hours.isEmpty, let coord = Self.libraryCoords[id] {
                    libraries.append(LibraryLocation(
                        id: id,
                        name: name,
                        hours: hours,
                        coordinate: coord
                    ))
                }
            }
        }
        
        // If scraping failed completely, fall back to default data
        if libraries.isEmpty {
            return Self.libraryCoords.map { (id, coord) in
                LibraryLocation(
                    id: id,
                    name: nameForLibraryID(id),
                    hours: defaultHours(for: id),
                    coordinate: coord
                )
            }
        }
        
        return libraries
    }
    
    private func normalizeTime(_ timeStr: String) -> String {
        // Convert any time format to 24-hour HH:mm
        let fmt = DateFormatter()
        fmt.locale = Locale(identifier: "en_US_POSIX")
        
        // Try 12-hour format first
        fmt.dateFormat = "h:mm a"
        if let date = fmt.date(from: timeStr) {
            fmt.dateFormat = "HH:mm"
            return fmt.string(from: date)
        }
        
        // Try 24-hour format
        fmt.dateFormat = "HH:mm"
        if let date = fmt.date(from: timeStr) {
            return fmt.string(from: date)
        }
        
        return timeStr // return original if we can't parse it
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
    
    private func defaultHours(for libraryId: String) -> [LibraryHours] {
        // Today is September 23, 2025 - using accurate hours from calendar
        let days = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]
        return days.map { day in
            switch day {
            case "Monday", "Tuesday", "Wednesday":
                // Current reduced hours period
                switch libraryId {
                case "arts": return LibraryHours(day: day, open: "12:00", close: "16:00")
                case "youngresearch": return LibraryHours(day: day, open: "10:00", close: "17:00")
                case "biomed": return LibraryHours(day: day, open: "10:00", close: "16:00")
                case "music": return LibraryHours(day: day, open: "12:00", close: "16:00")
                case "management": return LibraryHours(day: day, open: "12:00", close: "16:00")
                case "sel": return LibraryHours(day: day, open: "12:00", close: "16:00")
                case "eastasian": return LibraryHours(day: day, open: "10:00", close: "17:00")
                case "lawlib": return LibraryHours(day: day, open: "08:00", close: "21:30")
                case "powell": return LibraryHours(day: day, open: "10:00", close: "16:00")
                default: return LibraryHours(day: day, open: "10:00", close: "16:00")
                }
            case "Thursday":
                // Regular hours resume Thursday
                switch libraryId {
                case "arts": return LibraryHours(day: day, open: "09:00", close: "21:00")
                case "youngresearch": return LibraryHours(day: day, open: "08:00", close: "22:00")
                case "biomed": return LibraryHours(day: day, open: "08:00", close: "23:00")
                case "music": return LibraryHours(day: day, open: "09:00", close: "21:00")
                case "management": return LibraryHours(day: day, open: "09:00", close: "21:00")
                case "sel": return LibraryHours(day: day, open: "08:00", close: "21:00")
                case "eastasian": return LibraryHours(day: day, open: "10:00", close: "17:00")
                case "lawlib": return LibraryHours(day: day, open: "08:00", close: "21:30")
                case "powell": return LibraryHours(day: day, open: "08:00", close: "22:00")
                default: return LibraryHours(day: day, open: "09:00", close: "17:00")
                }
            case "Friday":
                switch libraryId {
                case "arts": return LibraryHours(day: day, open: "09:00", close: "17:00")
                case "youngresearch": return LibraryHours(day: day, open: "08:00", close: "18:00")
                case "biomed": return LibraryHours(day: day, open: "08:00", close: "18:00")
                case "music": return LibraryHours(day: day, open: "09:00", close: "17:00")
                case "management": return LibraryHours(day: day, open: "09:00", close: "18:00")
                case "sel": return LibraryHours(day: day, open: "08:00", close: "18:00")
                case "eastasian": return LibraryHours(day: day, open: "10:00", close: "17:00")
                case "lawlib": return LibraryHours(day: day, open: "08:00", close: "20:30")
                case "powell": return LibraryHours(day: day, open: "08:00", close: "18:00")
                default: return LibraryHours(day: day, open: "09:00", close: "17:00")
                }
            case "Saturday":
                switch libraryId {
                case "arts": return LibraryHours(day: day, open: "13:00", close: "17:00")
                case "youngresearch": return LibraryHours(day: day, open: "10:00", close: "18:00")
                case "biomed": return LibraryHours(day: day, open: "09:00", close: "17:00")
                case "music": return LibraryHours(day: day, open: "00:00", close: "00:00") // Closed
                case "management": return LibraryHours(day: day, open: "10:00", close: "19:00")
                case "sel": return LibraryHours(day: day, open: "00:00", close: "00:00") // Closed
                case "eastasian": return LibraryHours(day: day, open: "00:00", close: "00:00") // Closed
                case "lawlib": return LibraryHours(day: day, open: "09:00", close: "16:30")
                case "powell": return LibraryHours(day: day, open: "10:00", close: "18:00")
                default: return LibraryHours(day: day, open: "00:00", close: "00:00") // Closed
                }
            case "Sunday":
                switch libraryId {
                case "arts": return LibraryHours(day: day, open: "00:00", close: "00:00") // Closed
                case "youngresearch": return LibraryHours(day: day, open: "12:00", close: "21:00")
                case "biomed": return LibraryHours(day: day, open: "13:00", close: "22:00")
                case "music": return LibraryHours(day: day, open: "13:00", close: "17:00")
                case "management": return LibraryHours(day: day, open: "13:00", close: "21:00")
                case "sel": return LibraryHours(day: day, open: "13:00", close: "20:00")
                case "eastasian": return LibraryHours(day: day, open: "00:00", close: "00:00") // Closed
                case "lawlib": return LibraryHours(day: day, open: "13:00", close: "21:30")
                case "powell": return LibraryHours(day: day, open: "10:00", close: "21:00")
                default: return LibraryHours(day: day, open: "00:00", close: "00:00") // Closed
                }
            default:
                return LibraryHours(day: day, open: "00:00", close: "00:00") // Closed
            }
        }
    }
}
