import Foundation
import Combine

@MainActor
class DiningViewModel: ObservableObject {
    // MARK: Published state
    @Published var residential: [RowModel] = []
    @Published var retail: [RowModel] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published private var occupancyData: [String: WaitzPrediction] = [:]

    // MARK: Location
    let location = LocationManager()
    private var preferredOrigin: GeoPoint? = nil
    private var cancellables: Set<AnyCancellable> = []

    // MARK: Services
    private let service = DiningService()
    private let waitzService = WaitzService()

    // MARK: Row model (nested so views can reference DiningViewModel.RowModel)
    class RowModel: Identifiable, ObservableObject {
        let id: String
        let name: String
        let hall: DiningHall
        let distanceMiles: Double?
        let occupancy: WaitzPrediction?
        
        init(id: String, name: String, hall: DiningHall, distanceMiles: Double?, occupancy: WaitzPrediction?) {
            self.id = id
            self.name = name
            self.hall = hall
            self.distanceMiles = distanceMiles
            self.occupancy = occupancy
        }
    }

    init() {
        // Recompute distances & resort when user location updates
        location.$current
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.recomputeDistancesAndResort() }
            .store(in: &cancellables)
        
        // Start occupancy polling
        startOccupancyPolling()
    }
    
    private func startOccupancyPolling() {
        Task {
            while true {
                do {
                    self.occupancyData = try await waitzService.fetchOccupancy()
                    self.recomputeDistancesAndResort() // This will rebuild rows with new occupancy
                } catch {
                    print("Failed to fetch occupancy: \(error)")
                }
                try await Task.sleep(for: .seconds(60))
            }
        }
    }

    // MARK: - Public API
    func requestLocation() {
        location.request()
    }
    
    func load() {
        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil

        Task {
            defer { self.isLoading = false }

            do {
                // Fetch hall lists
                async let resHalls = service.fetchResidential()
                async let shopHalls = service.fetchCampusRetail()
                let (residentialHalls, campusRetail) = try await (resHalls, shopHalls)

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
                        distanceMiles: miles,
                        occupancy: occupancyData[hall.id]
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
                        distanceMiles: miles,
                        occupancy: occupancyData[hall.id]
                    )
                    retailRows.append(row)
                }

                sortByDistanceThenName(&resRows)
                sortByDistanceThenName(&retailRows)

                // Publish
                self.residential = resRows
                self.retail = retailRows

            } catch {
                self.errorMessage = "Failed to load dining data. Please try again."
                self.residential = []
                self.retail = []
            }
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
                           distanceMiles: miles, occupancy: r.occupancy)
            }
        }

        recompute(&residential)
        recompute(&retail)
        sortByDistanceThenName(&residential)
        sortByDistanceThenName(&retail)
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
        lhs.distanceMiles == rhs.distanceMiles &&
        lhs.occupancy == rhs.occupancy
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(name)
        hasher.combine(hall)
        hasher.combine(distanceMiles)
        hasher.combine(occupancy)
    }
}
