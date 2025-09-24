import Foundation
import CoreLocation

enum DistanceUnit { case miles }

struct DistanceCalculator {
    static func distance(from user: GeoPoint, to place: GeoPoint, unit: DistanceUnit = .miles) -> Double {
        let loc1 = CLLocation(latitude: user.lat, longitude: user.lon)
        let loc2 = CLLocation(latitude: place.lat, longitude: place.lon)
        let meters = loc1.distance(from: loc2)
        switch unit {
        case .miles: return meters / 1609.344
        }
    }
}
