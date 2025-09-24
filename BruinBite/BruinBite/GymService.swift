import Foundation

final class GymService {
    // This will eventually scrape UCLA gym hours
    // For now, returns mock data
    func fetchGyms() async throws -> [GymLocation] {
        // TODO: Replace with real scraping logic
        return [
            GymLocation(id: "johnwooden", name: "John Wooden Center", hours: [
                GymHours(day: "Monday", open: "06:00", close: "22:00"),
                GymHours(day: "Tuesday", open: "06:00", close: "22:00")
            ], coordinate: nil),
            GymLocation(id: "bfit", name: "Bfit", hours: [
                GymHours(day: "Monday", open: "07:00", close: "21:00"),
                GymHours(day: "Tuesday", open: "07:00", close: "21:00")
            ], coordinate: nil)
        ]
    }
}
