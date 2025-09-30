import Foundation

enum DiningFetchError: Error { case none }

/// Central place for your custom GPS pins. Edit these anytime.
struct GPSOverrides {
    // Residential halls (id -> lat/lon)
    static let halls: [String: GeoPoint] = [
        // YOUR PINS (from your messages)
        "TheStudyAtHedrick": GeoPoint(lat: 34.07332, lon: -118.45211), // “the stud”
        "FEASTAtRieber":     GeoPoint(lat: 34.07180, lon: -118.45135), // “feast”
        "BruinCafe":         GeoPoint(lat: 34.07267, lon: -118.45044), // “bruin cafe”
        "BruinPlate":        GeoPoint(lat: 34.07171, lon: -118.44988), // “bp”
        "Cafe1919":          GeoPoint(lat: 34.07257, lon: -118.45087), // “1919”
        "DeNeveDining":      GeoPoint(lat: 34.07054, lon: -118.45026), // “de neve”
        "EpicuriaAtAckerman":GeoPoint(lat: 34.07037, lon: -118.44431), // “epic at acer”
        "EpicuriaAtCovel":   GeoPoint(lat: 34.07283, lon: -118.45010), // “epic at covel”
        "Rendezvous":        GeoPoint(lat: 34.07253, lon: -118.45192), // “rendezvous”
        "TheDrey":           GeoPoint(lat: 34.07237, lon: -118.45331), // “the drey”
        // You can add more here if needed
    ]

    // Campus restaurants (id -> lat/lon). Reasonable entrance pins; tweak freely.
    static let campus: [String: GeoPoint] = [
        "LollicupFresh":      GeoPoint(lat: 34.07022, lon: -118.44494), // Ackerman L1 east
        "WetzelsPretzels":    GeoPoint(lat: 34.07019, lon: -118.44503),
        "Sweetspot":          GeoPoint(lat: 34.07016, lon: -118.44506),
        "PandaExpress":       GeoPoint(lat: 34.07023, lon: -118.44504),
        "Rubios":             GeoPoint(lat: 34.07025, lon: -118.44497),
        "VeggieGrill":        GeoPoint(lat: 34.07026, lon: -118.44490),
        "EpicuriaAck":        GeoPoint(lat: 34.07036, lon: -118.44499), // matches your “epic at acer”
        "CORE":               GeoPoint(lat: 34.07028, lon: -118.44486),
        "JambaBlendid":       GeoPoint(lat: 34.07015, lon: -118.44486),
        "KerckhoffCoffee":    GeoPoint(lat: 34.07079, lon: -118.44409),
        "NorthernLights":     GeoPoint(lat: 34.07088, lon: -118.44554),
        "Cafe451":            GeoPoint(lat: 34.06869, lon: -118.44193),
        "LuValleCommons":     GeoPoint(lat: 34.07531, lon: -118.43862),
        "CourtOfSciences":    GeoPoint(lat: 34.06854, lon: -118.44257),
        "MusicCafe":          GeoPoint(lat: 34.07064, lon: -118.43952),
        "SouthCampusFood":    GeoPoint(lat: 34.06655, lon: -118.44190)
    ]
}

final class DiningService {

    // MARK: Residential
    func fetchResidential() throws -> [DiningHall] {
        let halls: [DiningHall] = [
            DiningHall(id: "BruinPlate", name: "Bruin Plate", type: .residential, coordinate: GPSOverrides.halls["BruinPlate"]),
            DiningHall(id: "EpicuriaAtCovel", name: "Epicuria at Covel", type: .residential, coordinate: GPSOverrides.halls["EpicuriaAtCovel"]),
            DiningHall(id: "DeNeveDining", name: "De Neve Dining", type: .residential, coordinate: GPSOverrides.halls["DeNeveDining"]),
            DiningHall(id: "EpicuriaAtAckerman", name: "Epicuria at Ackerman", type: .residential, coordinate: GPSOverrides.halls["EpicuriaAtAckerman"]),
            DiningHall(id: "TheDrey", name: "The Drey", type: .residential, coordinate: GPSOverrides.halls["TheDrey"]),
            DiningHall(id: "TheStudyAtHedrick", name: "The Study at Hedrick", type: .residential, coordinate: GPSOverrides.halls["TheStudyAtHedrick"]),
            DiningHall(id: "Rendezvous", name: "Rendezvous", type: .residential, coordinate: GPSOverrides.halls["Rendezvous"]),
            DiningHall(id: "BruinCafe", name: "Bruin Café", type: .residential, coordinate: GPSOverrides.halls["BruinCafe"]),
            DiningHall(id: "Cafe1919", name: "Café 1919", type: .residential, coordinate: GPSOverrides.halls["Cafe1919"]),
            DiningHall(id: "FEASTAtRieber", name: "FEAST at Rieber", type: .residential, coordinate: GPSOverrides.halls["FEASTAtRieber"]),
            DiningHall(id: "FoodTrucks", name: "Food Trucks", type: .residential, coordinate: nil)
        ]
        return halls
    }

    // MARK: Campus retail (names only + coords)
    func fetchCampusRetail() throws -> [DiningHall] {
        let spots: [DiningHall] = [
            DiningHall(id: "LollicupFresh",   name: "Lollicup Fresh", type: .campusRetail, coordinate: GPSOverrides.campus["LollicupFresh"]),
            DiningHall(id: "WetzelsPretzels", name: "Wetzel’s Pretzels", type: .campusRetail, coordinate: GPSOverrides.campus["WetzelsPretzels"]),
            DiningHall(id: "Sweetspot",       name: "Sweetspot", type: .campusRetail, coordinate: GPSOverrides.campus["Sweetspot"]),
            DiningHall(id: "PandaExpress",    name: "Panda Express", type: .campusRetail, coordinate: GPSOverrides.campus["PandaExpress"]),
            DiningHall(id: "Rubios",          name: "Rubio’s", type: .campusRetail, coordinate: GPSOverrides.campus["Rubios"]),
            DiningHall(id: "VeggieGrill",     name: "Veggie Grill", type: .campusRetail, coordinate: GPSOverrides.campus["VeggieGrill"]),
            DiningHall(id: "EpicuriaAck",     name: "Epicuria at Ackerman", type: .campusRetail, coordinate: GPSOverrides.campus["EpicuriaAck"]),
            DiningHall(id: "CORE",            name: "CORE (Ready-to-Eat)", type: .campusRetail, coordinate: GPSOverrides.campus["CORE"]),
            DiningHall(id: "JambaBlendid",    name: "Jamba by Blendid", type: .campusRetail, coordinate: GPSOverrides.campus["JambaBlendid"]),
            DiningHall(id: "KerckhoffCoffee", name: "Kerckhoff Coffee House", type: .campusRetail, coordinate: GPSOverrides.campus["KerckhoffCoffee"]),
            DiningHall(id: "NorthernLights",  name: "Northern Lights", type: .campusRetail, coordinate: GPSOverrides.campus["NorthernLights"]),
            DiningHall(id: "Cafe451",         name: "Cafe 451", type: .campusRetail, coordinate: GPSOverrides.campus["Cafe451"]),
            DiningHall(id: "LuValleCommons",  name: "Lu Valle Commons", type: .campusRetail, coordinate: GPSOverrides.campus["LuValleCommons"]),
            DiningHall(id: "CourtOfSciences", name: "Court of Sciences Student Center", type: .campusRetail, coordinate: GPSOverrides.campus["CourtOfSciences"]),
            DiningHall(id: "MusicCafe",       name: "Music Café", type: .campusRetail, coordinate: GPSOverrides.campus["MusicCafe"]),
            DiningHall(id: "SouthCampusFood", name: "South Campus Food Court", type: .campusRetail, coordinate: GPSOverrides.campus["SouthCampusFood"])
        ]
        return spots
    }
    
    func fetchHTML() async throws -> String {
        let url = URL(string: "https://dining.ucla.edu/hours/")!
        let (data, _) = try await URLSession.shared.data(from: url)
        guard let html = String(data: data, encoding: .utf8) else {
            throw NSError(domain: "DiningService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to decode HTML"])
        }
        return html
    }

    func parseHours(from html: String) -> [String: MealHours] {
        var hoursDict = [String: MealHours]()
        
        // Find all tables
        let tableRegex = try? NSRegularExpression(pattern: "<table[^>]*>(.*?)</table>", options: [.caseInsensitive, .dotMatchesLineSeparators])
        guard let tableRegex else { print("DEBUG: failed to create table regex"); return hoursDict }
        let tableMatches = tableRegex.matches(in: html, options: [], range: NSRange(location: 0, length: html.count))
        print("DEBUG: found \(tableMatches.count) tables")
        
        for tableMatch in tableMatches {
            let tableRange = Range(tableMatch.range(at: 1), in: html)!
            let table = String(html[tableRange])
            print("DEBUG: parsing table with length \(table.count)")
            
            // Find all <tr>
            let trRegex = try? NSRegularExpression(pattern: "<tr[^>]*>(.*?)</tr>", options: [.caseInsensitive, .dotMatchesLineSeparators])
            guard let trRegex else { continue }
            let trMatches = trRegex.matches(in: table, options: [], range: NSRange(location: 0, length: table.count))
            print("DEBUG: found \(trMatches.count) rows in table")
            
            for match in trMatches {
                let trRange = Range(match.range(at: 1), in: table)!
                let trSubstring = table[trRange]
                let tr = String(trSubstring)
                // Find <td> or <th>
                let tdRegex = try? NSRegularExpression(pattern: "<t[dh][^>]*>(.*?)</t[dh]>", options: [.caseInsensitive, .dotMatchesLineSeparators])
                guard let tdRegex else { continue }
                let tdMatches = tdRegex.matches(in: tr, options: [], range: NSRange(location: 0, length: tr.count))
                print("DEBUG: tdMatches.count = \(tdMatches.count) for tr: \(tr.prefix(200))")
                if tdMatches.count >= 4 {
                    let nameIndex = tdMatches.count > 5 ? 1 : 0
                    let breakfastIndex = nameIndex + 1
                    let lunchIndex = nameIndex + 2
                    let dinnerIndex = nameIndex + 3
                    let lateNightIndex = tdMatches.count > nameIndex + 4 ? nameIndex + 4 : nil
                    
                    let nameRange = Range(tdMatches[nameIndex].range(at: 1), in: tr)!
                    let name = String(tr[nameRange]).trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: "&nbsp;", with: " ").replacingOccurrences(of: "&#160;", with: " ").replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression).replacingOccurrences(of: "&eacute;", with: "é").replacingOccurrences(of: "&#39;", with: "'").replacingOccurrences(of: "’", with: "'").replacingOccurrences(of: "é", with: "e").lowercased().replacingOccurrences(of: "[^a-z]", with: "", options: .regularExpression)
                    
                    let breakfastRange = Range(tdMatches[breakfastIndex].range(at: 1), in: tr)!
                    let breakfast = String(tr[breakfastRange]).trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: "&nbsp;", with: "").replacingOccurrences(of: "&#160;", with: "").replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression).replacingOccurrences(of: "a.m.", with: "am").replacingOccurrences(of: "p.m.", with: "pm")
                    
                    let lunchRange = Range(tdMatches[lunchIndex].range(at: 1), in: tr)!
                    let lunch = String(tr[lunchRange]).trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: "&nbsp;", with: "").replacingOccurrences(of: "&#160;", with: "").replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression).replacingOccurrences(of: "a.m.", with: "am").replacingOccurrences(of: "p.m.", with: "pm")
                    
                    let dinnerRange = Range(tdMatches[dinnerIndex].range(at: 1), in: tr)!
                    let dinner = String(tr[dinnerRange]).trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: "&nbsp;", with: "").replacingOccurrences(of: "&#160;", with: "").replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression).replacingOccurrences(of: "a.m.", with: "am").replacingOccurrences(of: "p.m.", with: "pm")
                    
                    let lateNight: String?
                    if let lateNightIndex = lateNightIndex {
                        let lateNightRange = Range(tdMatches[lateNightIndex].range(at: 1), in: tr)!
                        lateNight = String(tr[lateNightRange]).trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: "&nbsp;", with: "").replacingOccurrences(of: "&#160;", with: "").replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression).replacingOccurrences(of: "a.m.", with: "am").replacingOccurrences(of: "p.m.", with: "pm")
                    } else {
                        lateNight = nil
                    }
                    
                    let mealHours = MealHours(
                        breakfast: breakfast.lowercased() == "closed" || breakfast.isEmpty ? nil : convertTo24Hour(breakfast),
                        lunch: lunch.lowercased() == "closed" || lunch.isEmpty ? nil : convertTo24Hour(lunch),
                        dinner: dinner.lowercased() == "closed" || dinner.isEmpty ? nil : convertTo24Hour(dinner),
                        lateNight: lateNight?.lowercased() == "closed" || lateNight?.isEmpty == true ? nil : convertTo24Hour(lateNight!)
                    )
                    hoursDict[name] = mealHours
                    print("DEBUG: added hours for \(name): \(mealHours)")
                }
            }
        }
        print("DEBUG: final parsed hoursDict = \(hoursDict)")
        return hoursDict
    }
    
    private func convertTo24Hour(_ timeString: String) -> String {
        let components = timeString.components(separatedBy: " - ")
        var converted = [String]()
        for comp in components {
            let trimmed = comp.trimmingCharacters(in: .whitespaces)
            if let convertedTime = convertSingleTime(trimmed) {
                converted.append(convertedTime)
            } else {
                converted.append(trimmed) // fallback
            }
        }
        return converted.joined(separator: " - ")
    }
    
    private func convertSingleTime(_ time: String) -> String? {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mma"
        if let date = formatter.date(from: time) {
            formatter.dateFormat = "HH:mm"
            return formatter.string(from: date)
        }
        return nil
    }
}
