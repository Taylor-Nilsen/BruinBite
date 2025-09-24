import Foundation

struct WaitzResponse: Codable {
    let locations: [WaitzLocation]
    
    struct WaitzLocation: Codable {
        let id: Int
        let name: String
        let capacity: Int
        let busyness: String
        let percentage: Int
    }
    
    private static let locationMapping = [
        "Bruin Plate Residential Restaurant": "BruinPlate",
        "De Neve Residential Restaurant": "DeNeveDining",
        "Covel Residential Restaurant": "EpicuriaAtCovel",
        "Rendezvous": "Rendezvous",
        "Bruin Café": "BruinCafe",
        "The Study at Hedrick": "TheStudyAtHedrick",
        "FEAST at Rieber": "FEASTAtRieber",
        "Epicuria": "EpicuriaAtAckerman",
        "Café 1919": "Cafe1919",
        "The Drey": "TheDrey"
    ]
    
    var predictions: [String: WaitzPrediction] {
        var result: [String: WaitzPrediction] = [:]
        for loc in locations {
            if let id = Self.locationMapping[loc.name] {
                result[id] = WaitzPrediction(percentage: loc.percentage, busyness: loc.busyness)
            }
        }
        return result
    }
}

struct WaitzPrediction: Codable, Hashable {
    let percentage: Int
    let busyness: String
}

final class WaitzService {
    private let url = URL(string: "https://api.waitz.io/v3/live/UCLA")!
    
    func fetchOccupancy() async throws -> [String: WaitzPrediction] {
        let (data, response) = try await URLSession.shared.data(from: url)
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        
        let waitzData = try JSONDecoder().decode(WaitzResponse.self, from: data)
        return waitzData.predictions
    }
}
