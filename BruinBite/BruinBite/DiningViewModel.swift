import Foundation
import Combine
import SwiftUI

@MainActor
class DiningViewModel: ObservableObject {
    // MARK: Published state
    @Published var residential: [RowModel] = []
    @Published var retail: [RowModel] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    // MARK: Location
    let location = LocationManager()
    private var preferredOrigin: GeoPoint? = nil
    private var cancellables: Set<AnyCancellable> = []

    // MARK: Services
    private let service = DiningService()

    // MARK: Row model (nested so views can reference DiningViewModel.RowModel)
    class RowModel: Identifiable, ObservableObject {
        let id: String
        let name: String
        let hall: DiningHall
        let distanceMiles: Double?
        @Published var isOpen: Bool = false
        @Published var statusText: String? = "loading"
        @Published var statusColor: Color = .gray
        
        private var isUpdating = false
        
        init(id: String, name: String, hall: DiningHall, distanceMiles: Double?, hours: MealHours? = nil) {
            self.id = id
            self.name = name
            self.hall = hall
            self.distanceMiles = distanceMiles
            self.diningHours = hours
        }
        
        @Published var diningHours: MealHours? {
            didSet {
                if isUpdating { return }
                isUpdating = true
                if var h = diningHours {
                    updateStatus(with: &h)
                    self.diningHours = h
                }
                isUpdating = false
            }
        }
        
        func updateStatus(with hours: inout MealHours) {
            if hall.type == .campusRetail {
                isOpen = true
                statusText = nil
                statusColor = .gray
                return
            }
            
            let now = Date()
            var intervals: [(start: Date, end: Date)] = []
            
            let formatter1 = DateFormatter()
            formatter1.dateFormat = "h:mm a"
            formatter1.locale = Locale(identifier: "en_US_POSIX")
            let formatter2 = DateFormatter()
            formatter2.dateFormat = "h:mma"
            formatter2.locale = Locale(identifier: "en_US_POSIX")
            let formatter24 = DateFormatter()
            formatter24.dateFormat = "HH:mm"
            formatter24.locale = Locale(identifier: "en_US_POSIX")
            
            func parseTime(_ timeStr: String) -> Date? {
                return formatter1.date(from: timeStr) ?? formatter2.date(from: timeStr)
            }
            
            let calendar = Calendar.current
            let today = calendar.startOfDay(for: now)
            
            func parseTimeRange(_ rangeStr: String) -> ((Date, Date), String)? {
                let parts = rangeStr.components(separatedBy: CharacterSet(charactersIn: "-")).map { $0.trimmingCharacters(in: .whitespaces) }
                if parts.count == 2,
                   let startTime = parseTime(parts[0]),
                   let endTime = parseTime(parts[1]) {
                    let start = calendar.date(bySettingHour: calendar.component(.hour, from: startTime),
                                              minute: calendar.component(.minute, from: startTime),
                                              second: 0, of: today)!
                    var end = calendar.date(bySettingHour: calendar.component(.hour, from: endTime),
                                            minute: calendar.component(.minute, from: endTime),
                                            second: 0, of: today)!
                    if end < start {
                        // Assume late night spans to next day
                        end = calendar.date(byAdding: .day, value: 1, to: end)!
                    }
                    let startStr = formatter24.string(from: start)
                    let endStr = formatter24.string(from: end)
                    let formatted = "\(startStr) - \(endStr)"
                    return ((start, end), formatted)
                }
                return nil
            }
            
            if let breakfast = hours.breakfast, let result = parseTimeRange(breakfast) {
                intervals.append(result.0)
                hours.breakfast = result.1
            }
            if let lunch = hours.lunch, let result = parseTimeRange(lunch) {
                intervals.append(result.0)
                hours.lunch = result.1
            }
            if let dinner = hours.dinner, let result = parseTimeRange(dinner) {
                intervals.append(result.0)
                hours.dinner = result.1
            }
            if let lateNight = hours.lateNight, let result = parseTimeRange(lateNight) {
                intervals.append(result.0)
                hours.lateNight = result.1
            }
            
            intervals.sort { $0.start < $1.start }
            print("DEBUG: intervals = \(intervals.map { (formatter24.string(from: $0.start), formatter24.string(from: $0.end)) })")
            print("DEBUG: now = \(formatter24.string(from: now))")
            
            if let currentInterval = intervals.first(where: { now >= $0.start && now <= $0.end }) {
                // Open
                isOpen = true
                let endStr = formatter24.string(from: currentInterval.end)
                statusText = endStr
                statusColor = .green
                print("DEBUG: Open until \(endStr)")
            } else {
                // Closed, find next opening
                if let nextInterval = intervals.first(where: { $0.start > now }) {
                    isOpen = false
                    let startStr = formatter24.string(from: nextInterval.start)
                    statusText = startStr
                    statusColor = .red
                    print("DEBUG: Closed, opens at \(startStr)")
                } else {
                    // No more today
                    isOpen = false
                    statusText = "closed"
                    statusColor = .red
                    print("DEBUG: Closed, no more openings today")
                }
            }
        }
    }

    init() {
        // Recompute distances & resort when user location updates
        location.$current
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.recomputeDistancesAndResort() }
            .store(in: &cancellables)
        
        // Load initial data
        load()
    }
    
    // MARK: - Public API
    func requestLocation() {
        location.request()
    }
    
    func load() {
        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil

        defer { self.isLoading = false }

        do {
            // Fetch hall lists
            let residentialHalls = try service.fetchResidential()
            let campusRetail = try service.fetchCampusRetail()

            var resRows: [RowModel] = []
            var retailRows: [RowModel] = []

            // Build rows per hall
            for hall in residentialHalls {
                // distance
                var miles: Double? = nil
                if let origin = currentOrigin(), let coord = hall.coordinate {
                    miles = DistanceCalculator.distance(from: origin, to: coord, unit: .miles)
                }

                // build row
                let row = RowModel(
                    id: hall.id,
                    name: hall.name,
                    hall: hall,
                    distanceMiles: miles
                )
                resRows.append(row)
            }

            for hall in campusRetail {
                var miles: Double? = nil
                if let origin = currentOrigin(), let coord = hall.coordinate {
                    miles = DistanceCalculator.distance(from: origin, to: coord, unit: .miles)
                }

                let row = RowModel(
                    id: hall.id,
                    name: hall.name,
                    hall: hall,
                    distanceMiles: miles
                )
                retailRows.append(row)
            }

            sortByDistanceThenName(&resRows)
            sortByDistanceThenName(&retailRows)

            // Publish
            self.residential = resRows
            self.retail = retailRows

            // Fetch hours asynchronously
            Task { await self.fetchHours() }

        } catch {
            self.errorMessage = "Failed to load dining data. Please try again."
            self.residential = []
            self.retail = []
        }
    }

    // MARK: - Helpers

    private func currentOrigin() -> GeoPoint? {
        preferredOrigin ?? location.current
    }

    private func recomputeDistancesAndResort() {
        let origin = currentOrigin()

        func recompute(_ rows: inout [RowModel]) {
            rows = rows.map { r in
                var miles = r.distanceMiles
                if let origin, let coord = r.hall.coordinate {
                    miles = DistanceCalculator.distance(from: origin, to: coord, unit: .miles)
                }
                return .init(id: r.id, name: r.name, hall: r.hall,
                           distanceMiles: miles, hours: r.diningHours)
            }
        }

        recompute(&residential)
        recompute(&retail)
        sortByDistanceThenName(&residential)
        sortByDistanceThenName(&retail)
    }

    private func fetchHours() async {
        do {
            let html = try await service.fetchHTML()
            print("DEBUG: HTML length: \(html.count)")
            print("DEBUG: HTML prefix: \(html.prefix(1000))")
            let hoursDict = service.parseHours(from: html)
            print("DEBUG: hoursDict = \(hoursDict)")
            await MainActor.run {
                for row in self.residential {
                    let key = row.name.lowercased().replacingOccurrences(of: "é", with: "e").replacingOccurrences(of: "’", with: "'").replacingOccurrences(of: "[^a-z]", with: "", options: .regularExpression)
                    let hours = hoursDict[key]
                    print("DEBUG: setting hours for \(row.name) (key: \(key)): \(hours)")
                    row.diningHours = hours
                }
                for row in self.retail {
                    let key = row.name.lowercased().replacingOccurrences(of: "é", with: "e").replacingOccurrences(of: "’", with: "'").replacingOccurrences(of: "[^a-z]", with: "", options: .regularExpression)
                    let hours = hoursDict[key]
                    print("DEBUG: setting hours for \(row.name) (key: \(key)): \(hours)")
                    row.diningHours = hours
                }
            }
        } catch {
            print("DEBUG: Error fetching hours: \(error)")
            // Optionally set error, but for now ignore
        }
    }

    private func sortByDistanceThenName(_ rows: inout [RowModel]) {
        if let origin = currentOrigin() {
            rows.sort {
                let a = $0.distanceMiles ?? ( $0.hall.coordinate.map { DistanceCalculator.distance(from: origin, to: $0, unit: .miles) } ?? Double.greatestFiniteMagnitude )
                let b = $1.distanceMiles ?? ( $1.hall.coordinate.map { DistanceCalculator.distance(from: origin, to: $0, unit: .miles) } ?? Double.greatestFiniteMagnitude )
                return a == b ? $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending : a < b
            }
        } else {
            rows.sort { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        }
    }

    private func sortCampusByDistanceThenName(_ halls: [DiningHall]) -> [DiningHall] {
        guard let origin = currentOrigin() else {
            return halls.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        }
        return halls.sorted { a, b in
            let da = a.coordinate.map { DistanceCalculator.distance(from: origin, to: $0, unit: .miles) } ?? Double.greatestFiniteMagnitude
            let db = b.coordinate.map { DistanceCalculator.distance(from: origin, to: $0, unit: .miles) } ?? Double.greatestFiniteMagnitude
            return da == db ? a.name.localizedCaseInsensitiveCompare(b.name) == .orderedAscending : da < db
        }
    }
}

// Extension to add Hashable and Equatable conformance
extension DiningViewModel.RowModel: Hashable {
    static func == (lhs: DiningViewModel.RowModel, rhs: DiningViewModel.RowModel) -> Bool {
        lhs.id == rhs.id &&
        lhs.name == rhs.name &&
        lhs.hall == rhs.hall &&
        lhs.distanceMiles == rhs.distanceMiles
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(name)
        hasher.combine(hall)
        hasher.combine(distanceMiles)
    }
}
