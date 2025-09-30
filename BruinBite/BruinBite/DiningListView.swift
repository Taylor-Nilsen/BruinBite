import SwiftUI

/// Represents the two main tabs in the dining section
enum DiningListMode {
    case halls
    case campus
}

/// Main list view containing dining hall entries
/// Each row in the list is called an "entry" and tapping it opens a "card" view
struct DiningListView: View {
    @StateObject private var vm: DiningViewModel
    let mode: DiningListMode
    
    init(vm: DiningViewModel, mode: DiningListMode) {
        _vm = StateObject(wrappedValue: vm)
        self.mode = mode
    }

    var body: some View {
        Group {
            switch mode {
            case .halls:
                if vm.isLoading && vm.residential.isEmpty {
                    ProgressView("Loading…").padding()
                } else if let err = vm.errorMessage, vm.residential.isEmpty {
                    VStack(spacing: 12) {
                        Text(err).multilineTextAlignment(.center)
                        Button("Retry") {
                            Task {
                                await vm.load()
                            }
                        }
                    }
                    .padding()
                } else {
                    List {
                        Section("Residential Dining") {
                            ForEach(vm.residential) { row in
                                NavigationLink(destination: DiningDetailView(row: row)) {
                                    HallRow(row: row)
                                }
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                    .refreshable {
                        await vm.load()
                    }
                }
                
            case .campus:
                if vm.isLoading && vm.retail.isEmpty {
                    ProgressView("Loading…").padding()
                } else if let err = vm.errorMessage, vm.retail.isEmpty {
                    VStack(spacing: 12) {
                        Text(err).multilineTextAlignment(.center)
                        Button("Retry") {
                            Task {
                                await vm.load()
                            }
                        }
                    }
                    .padding()
                } else {
                    List {
                        Section("Campus Retail") {
                            ForEach(vm.retail) { row in
                                NavigationLink(destination: CampusDetailView(row: row)) {
                                    CampusRow(row: row)
                                }
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                    .refreshable {
                        await vm.load()
                    }
                }
            }
        }
        .navigationTitle(mode == .halls ? "Halls" : "Campus")
        .task {
            vm.requestLocation()
            await vm.load()
        }
    }
}

// MARK: - Rows

private struct HallRow: View {
    let row: DiningViewModel.RowModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline) {
                Text(row.name)
                    .appFont(.headline)
                Spacer(minLength: 12)
            }
            
            if let distance = row.distanceMiles {
                Text(String(format: "%.2f mi", distance))
                    .appFont(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

private struct CampusRow: View {
    let row: DiningViewModel.RowModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline) {
                Text(row.name)
                    .appFont(.headline)
                Spacer(minLength: 12)
            }
            
            if let distance = row.distanceMiles {
                Text(String(format: "%.2f mi", distance))
                    .appFont(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

#Preview {
    NavigationStack {
        DiningListView(vm: PreviewDiningViewModel(), mode: .halls)
    }
}

private class PreviewDiningViewModel: DiningViewModel {
    override func load() {
        // Simulated data for preview
        self.residential = [
            RowModel(
                id: "BruinPlate",
                name: "Bruin Plate",
                hall: DiningHall(id: "BruinPlate", name: "Bruin Plate", url: nil, type: .residential, coordinate: GeoPoint(lat: 34.0720, lon: -118.4521)),
                distanceMiles: 0.2,
                occupancy: WaitzPrediction(percentage: 75, busyness: "busy")
            ),
            RowModel(
                id: "DeNeveDining",
                name: "De Neve Dining",
                hall: DiningHall(id: "DeNeveDining", name: "De Neve Dining", url: nil, type: .residential, coordinate: GeoPoint(lat: 34.0720, lon: -118.4521)),
                distanceMiles: 0.3,
                occupancy: nil
            )
        ]
        self.retail = [
            RowModel(
                id: "CORE",
                name: "CORE (Ready-to-Eat)",
                hall: DiningHall(id: "CORE", name: "CORE (Ready-to-Eat)", url: nil, type: .campusRetail, coordinate: GeoPoint(lat: 34.0720, lon: -118.4521)),
                distanceMiles: 0.1,
                occupancy: nil
            ),
            RowModel(
                id: "PandaExpress",
                name: "Panda Express",
                hall: DiningHall(id: "PandaExpress", name: "Panda Express", url: nil, type: .campusRetail, coordinate: GeoPoint(lat: 34.0720, lon: -118.4521)),
                distanceMiles: 0.15,
                occupancy: nil
            )
        ]
    }
}

struct DiningListView_Previews: PreviewProvider {
    static var previews: some View {
        DiningListView(vm: PreviewDiningViewModel(), mode: .halls)
    }
}
