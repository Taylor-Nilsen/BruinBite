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
            DiningHall(id: "FEASTAtRieber", name: "FEAST at Rieber", type: .residential, coordinate: GPSOverrides.halls["FEASTAtRieber"])
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
}
