import Foundation
import Combine

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
        @Published var hours: MealHours?
        
        init(id: String, name: String, hall: DiningHall, distanceMiles: Double?, hours: MealHours? = nil) {
            self.id = id
            self.name = name
            self.hall = hall
            self.distanceMiles = distanceMiles
            self.hours = hours
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
                           distanceMiles: miles, hours: r.hours)
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
            let hoursDict = service.parseHours(from: html)
            await MainActor.run {
                for row in self.residential {
                    row.hours = hoursDict[row.name.lowercased()]
                }
                for row in self.retail {
                    row.hours = hoursDict[row.name.lowercased()]
                }
            }
        } catch {
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
