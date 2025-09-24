import Foundation
import Combine

@MainActor
class DiningViewModel: ObservableObject {
    // MARK: Published state
    @Published var residentialOpen: [RowModel] = []
    @Published var residentialClosed: [RowModel] = []
    @Published var retailOpen: [RowModel] = []
    @Published var retailClosed: [RowModel] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published private var occupancyData: [String: WaitzPrediction] = [:]

    // MARK: Location
    let location = LocationManager()
    private var preferredOrigin: GeoPoint? = nil
    private var cancellables: Set<AnyCancellable> = []

    // MARK: Services
    private let service = DiningService()
    private let hours = HoursProvider()
    private let waitzService = WaitzService()

    // MARK: Row model (nested so views can reference DiningViewModel.RowModel)
    struct RowModel: Identifiable, Hashable {
        let id: String
        let name: String
        let hall: DiningHall
        let openNow: Bool
        let currentMeal: String?
        let nextChangeAt: Date?
        let nextChangeType: HallStatus.ChangeType?
        let distanceMiles: Double?
        let occupancy: WaitzPrediction?
        let todayWindows: DayWindows?  // Today's service windows
        
        var operatingHours: String {
            guard let windows = todayWindows else { return "Closed" }
            
            let formatter = DateFormatter()
            formatter.dateFormat = "H:mm"
            
            // Get first and last service windows of the day
            if let first = windows.intervals.min(by: { $0.start < $1.start }),
               let last = windows.intervals.max(by: { $0.end < $1.end }) {
                return "\(formatter.string(from: first.start))-\(formatter.string(from: last.end))"
            }
            
            return "Closed"
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

                let now = Date()
                var openRows: [RowModel] = []
                var closedRows: [RowModel] = []
                var retailOpenRows: [RowModel] = []
                var retailClosedRows: [RowModel] = []

                // Build rows per hall using statusNow() and windows()
                for hall in residentialHalls {
                    let st = try? await hours.statusNow(for: hall.id, now: now)
                    let todayWindows = try? await hours.windows(for: hall.id, on: now)
                    let isOpen = st?.openNow ?? false

                    // distance
                    var miles: Double? = nil
                    if let origin = currentOrigin(), let coord = hall.coordinate {
                        miles = DistanceCalculator.distance(from: origin, to: coord, unit: .miles)
                    }

                    // build row with actual service windows
                    let row = RowModel(
                        id: hall.id,
                        name: hall.name,
                        hall: hall,
                        openNow: isOpen,
                        currentMeal: st?.currentMeal,
                        nextChangeAt: st?.nextChangeAt,
                        nextChangeType: st?.nextChangeType,
                        distanceMiles: miles,
                        occupancy: occupancyData[hall.id],
                        todayWindows: todayWindows
                    )

                    if isOpen { openRows.append(row) } else { closedRows.append(row) }
                }

                // Build retail rows with status and windows
                for hall in campusRetail {
                    let st = try? await hours.statusNow(for: hall.id, now: now)
                    let todayWindows = try? await hours.windows(for: hall.id, on: now)
                    let isOpen = st?.openNow ?? false

                    // distance
                    var miles: Double? = nil
                    if let origin = currentOrigin(), let coord = hall.coordinate {
                        miles = DistanceCalculator.distance(from: origin, to: coord, unit: .miles)
                    }

                    // build row with actual service windows
                    let row = RowModel(
                        id: hall.id,
                        name: hall.name,
                        hall: hall,
                        openNow: isOpen,
                        currentMeal: st?.currentMeal,
                        nextChangeAt: st?.nextChangeAt,
                        nextChangeType: st?.nextChangeType,
                        distanceMiles: miles,
                        occupancy: occupancyData[hall.id],
                        todayWindows: todayWindows
                    )

                    if isOpen { retailOpenRows.append(row) } else { retailClosedRows.append(row) }
                }

                // Sort rows
                sortByDistanceThenName(&openRows)
                sortByDistanceThenName(&closedRows)
                sortByDistanceThenName(&retailOpenRows)
                sortByDistanceThenName(&retailClosedRows)

                // Publish
                self.residentialOpen = openRows
                self.residentialClosed = closedRows
                self.retailOpen = retailOpenRows
                self.retailClosed = retailClosedRows

            } catch {
                self.errorMessage = "Failed to load dining data. Please try again."
                self.residentialOpen = []
                self.residentialClosed = []
                self.retailOpen = []
                self.retailClosed = []
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
                           openNow: r.openNow, currentMeal: r.currentMeal,
                           nextChangeAt: r.nextChangeAt, nextChangeType: r.nextChangeType,
                           distanceMiles: miles, occupancy: r.occupancy, todayWindows: r.todayWindows)
            }
        }

        recompute(&residentialOpen)
        recompute(&residentialClosed)
        recompute(&retailOpen)
        recompute(&retailClosed)
        sortByDistanceThenName(&residentialOpen)
        sortByDistanceThenName(&residentialClosed)
        sortByDistanceThenName(&retailOpen)
        sortByDistanceThenName(&retailClosed)
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
