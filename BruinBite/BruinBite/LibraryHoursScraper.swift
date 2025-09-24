import Foundation

enum LibraryHoursError: Error {
    case invalidURL
    case networkError(Error)
    case invalidData
}

struct LibrarySchedule {
    let mainHours: String
    let nightHours: String?
    let cliccHours: String?
    let equipmentHours: String?
}

class LibraryHoursScraper {
    static let shared = LibraryHoursScraper()
    private let baseURL = "https://calendar.library.ucla.edu/hours"
    
    func fetchLibraryHours() async throws -> [String: LibrarySchedule] {
        guard let url = URL(string: baseURL) else {
            throw LibraryHoursError.invalidURL
        }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200,
              let htmlString = String(data: data, encoding: .utf8) else {
            throw LibraryHoursError.invalidData
        }
        
        return parseLibraryHours(from: htmlString)
    }
    
    private func parseLibraryHours(from html: String) -> [String: LibrarySchedule] {
        var schedules: [String: LibrarySchedule] = [:]
        
        // Find library sections using more specific selectors
        let sections = html.components(separatedBy: "<div class=\"s-lc-whw-loc\">")
        
        for section in sections {
            if section.contains("Powell Library") {
                // Extract main hours looking for today's hours specifically
                let mainHours = findHours(in: section, nearTerm: "Today") ?? findHours(in: section, nearTerm: "Hours") ?? "10:00-16:00"
                
                // Look for Night Powell hours with various possible labels
                let nightHours = findHours(in: section, nearTerm: "Night Powell") ?? findHours(in: section, nearTerm: "Night Study")
                
                // Look for CLICC hours with various formats
                let cliccHours = findHours(in: section, nearTerm: "CLICC") ?? findHours(in: section, nearTerm: "Computer Lab")
                
                // Look for Equipment hours
                let equipmentHours = findHours(in: section, nearTerm: "Equipment") ?? findHours(in: section, nearTerm: "Lending")
                
                schedules["powell"] = LibrarySchedule(
                    mainHours: mainHours,
                    nightHours: nightHours,
                    cliccHours: cliccHours,
                    equipmentHours: equipmentHours
                )
            }
        }
        
        return schedules
    }
    
    private func findHours(in text: String, nearTerm term: String) -> String? {
        let searchArea: String
        if let range = text.range(of: term) {
            // Look in the 200 characters after the term
            let startIndex = range.lowerBound
            let endIndex = text.index(startIndex, offsetBy: 200, limitedBy: text.endIndex) ?? text.endIndex
            searchArea = String(text[startIndex..<endIndex])
        } else {
            return nil
        }
        
        // Look for time patterns
        let timePatterns = [
            #"(\d{1,2}:\d{2})\s*(?:AM|PM|am|pm)?\s*-\s*(\d{1,2}:\d{2})\s*(?:AM|PM|am|pm)?"#,
            #"(\d{1,2}:\d{2})\s*-\s*(\d{1,2}:\d{2})"#,
            #"(\d{1,2}):\s*(\d{2})\s*(?:AM|PM|am|pm)?\s*-\s*(\d{1,2}):\s*(\d{2})\s*(?:AM|PM|am|pm)?"#
        ]
        
        for pattern in timePatterns {
            if let range = searchArea.range(of: pattern, options: .regularExpression) {
                let match = searchArea[range]
                return normalizeTimeRange(String(match))
            }
        }
        
        return nil
    }
    
    private func normalizeTimeRange(_ timeRange: String) -> String {
        let components = timeRange
            .components(separatedBy: CharacterSet(charactersIn: "- "))
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        
        guard components.count >= 2 else { return timeRange }
        
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        
        var normalizedStart = components[0]
        var normalizedEnd = components[1]
        
        // Try to parse and normalize times
        let timeFormats = ["h:mm a", "H:mm", "h:mma", "ha", "HH:mm"]
        for format in timeFormats {
            formatter.dateFormat = format
            if let startDate = formatter.date(from: components[0]),
               let endDate = formatter.date(from: components[1]) {
                formatter.dateFormat = "HH:mm"
                normalizedStart = formatter.string(from: startDate)
                normalizedEnd = formatter.string(from: endDate)
                break
            }
        }
        
        return "\(normalizedStart)-\(normalizedEnd)"
    }
}
