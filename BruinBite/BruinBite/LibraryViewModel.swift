import Foundation
import Combine

@MainActor
final class LibraryViewModel: ObservableObject {
    @Published var libraries: [LibraryLocation] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let service = LibraryDataService()
    private var cancellables: Set<AnyCancellable> = []
    let location = LocationManager()

    init() {
        // Recompute distances & resort when user location updates
        location.$current
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.sortLibraries() }
            .store(in: &cancellables)
    }

    func load() {
        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil
        Task {
            defer { self.isLoading = false }
            do {
                let libs = try await service.fetchLibraries()
                self.libraries = libs
                sortLibraries()
            } catch {
                self.errorMessage = "Failed to load library data. Please try again."
                self.libraries = []
            }
        }
    }

    private func sortLibraries() {
        guard let userLocation = location.current else {
            // If no location, sort alphabetically
            libraries.sort { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
            return
        }

        // Sort by distance, then name
        libraries.sort { lib1, lib2 in
            let dist1 = lib1.coordinate.map { DistanceCalculator.distance(from: userLocation, to: $0) } ?? Double.greatestFiniteMagnitude
            let dist2 = lib2.coordinate.map { DistanceCalculator.distance(from: userLocation, to: $0) } ?? Double.greatestFiniteMagnitude
            return dist1 == dist2 ? lib1.name.localizedCaseInsensitiveCompare(lib2.name) == .orderedAscending : dist1 < dist2
        }
    }

    func distanceToLibrary(_ library: LibraryLocation) -> Double? {
        guard let userLocation = location.current,
              let libraryLocation = library.coordinate else { return nil }
        return DistanceCalculator.distance(from: userLocation, to: libraryLocation)
    }
}
