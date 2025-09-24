import SwiftUI

struct LibraryListView: View {
    @StateObject private var viewModel = LibraryViewModel()
    
    var body: some View {
        Group {
            if viewModel.isLoading && viewModel.libraries.isEmpty {
                ProgressView("Loading…").padding()
            } else if let err = viewModel.errorMessage, viewModel.libraries.isEmpty {
                VStack(spacing: 12) {
                    Text(err).multilineTextAlignment(.center)
                    Button("Retry") {
                        Task {
                            await viewModel.load()
                        }
                    }
                }
                .padding()
            } else {
                List {
                    if !openLibraries.isEmpty {
                        Section("Open Now") {
                            ForEach(openLibraries) { library in
                                NavigationLink(destination: LibraryDetailView(library: library, distanceMiles: viewModel.distanceToLibrary(library))) {
                                    LibraryRow(library: library, hours: todayHours(for: library), distance: viewModel.distanceToLibrary(library))
                                }
                            }
                        }
                    }
                    if !closedLibraries.isEmpty {
                        Section("Closed") {
                            ForEach(closedLibraries) { library in
                                NavigationLink(destination: LibraryDetailView(library: library, distanceMiles: viewModel.distanceToLibrary(library))) {
                                    LibraryRow(library: library, hours: todayHours(for: library), distance: viewModel.distanceToLibrary(library))
                                }
                            }
                        }
                    }
                }
                .listStyle(.insetGrouped)
                .refreshable {
                    await viewModel.load()
                }
            }
        }
        .navigationTitle("Study")
        .task {
            await viewModel.load()
        }
    }

    private var openLibraries: [LibraryLocation] {
        viewModel.libraries.filter { isLibraryOpen($0) }
    }
    
    private var closedLibraries: [LibraryLocation] {
        viewModel.libraries.filter { !isLibraryOpen($0) }
    }
    
    private func isLibraryOpen(_ library: LibraryLocation) -> Bool {
        guard let hours = todayHours(for: library) else { return false }
        
        let now = Date()
        let calendar = Calendar.current
        let currentMinutes = calendar.component(.hour, from: now) * 60 + calendar.component(.minute, from: now)
        
        let openComponents = hours.open.split(separator: ":").compactMap { Int($0) }
        let closeComponents = hours.close.split(separator: ":").compactMap { Int($0) }
        
        guard openComponents.count == 2, closeComponents.count == 2 else { return false }
        
        let openMinutes = openComponents[0] * 60 + openComponents[1]
        let closeMinutes = closeComponents[0] * 60 + closeComponents[1]
        
        return currentMinutes >= openMinutes && currentMinutes <= closeMinutes
    }
    
    private func todayHours(for library: LibraryLocation) -> LibraryHours? {
        let weekday = Calendar.current.weekdaySymbols[Calendar.current.component(.weekday, from: Date()) - 1]
        return library.hours.first { $0.day == weekday }
    }
}

private struct LibraryRow: View {
    let library: LibraryLocation
    let hours: LibraryHours?
    let distance: Double?
    
    private var isOpen: Bool {
        guard let hours = hours else { return false }
        let now = Date()
        let calendar = Calendar.current
        let currentMinutes = calendar.component(.hour, from: now) * 60 + calendar.component(.minute, from: now)
        
        let openComponents = hours.open.split(separator: ":").compactMap { Int($0) }
        let closeComponents = hours.close.split(separator: ":").compactMap { Int($0) }
        
        guard openComponents.count == 2, closeComponents.count == 2 else { return false }
        
        let openMinutes = openComponents[0] * 60 + openComponents[1]
        let closeMinutes = closeComponents[0] * 60 + closeComponents[1]
        
        return currentMinutes >= openMinutes && currentMinutes <= closeMinutes
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline) {
                Text(library.name)
                    .appFont(.headline)
                    .lineLimit(1)
                Spacer(minLength: 12)
                
                if let hours = hours {
                    Text(isOpen ? hours.close : hours.open)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(isOpen ? .green : .red)
                        .monospacedDigit()
                }
            }
            
            if let distance = distance {
                Text(String(format: "%.2f mi", distance))
                    .appFont(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

#Preview {
    NavigationStack {
        LibraryListView()
    }
}
