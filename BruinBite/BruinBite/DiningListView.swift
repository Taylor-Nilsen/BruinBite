import SwiftUI

enum DiningListMode {
    case halls
    case campus
}

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
                if vm.isLoading && vm.residentialOpen.isEmpty && vm.residentialClosed.isEmpty {
                    ProgressView("Loading…").padding()
                } else if let err = vm.errorMessage, vm.residentialOpen.isEmpty && vm.residentialClosed.isEmpty {
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
                        if !vm.residentialOpen.isEmpty {
                            Section("Open Now") {
                                ForEach(vm.residentialOpen) { row in
                                    NavigationLink(destination: DiningDetailView(row: row)) {
                                        HallRow(row: row)
                                    }
                                }
                            }
                        }
                        if !vm.residentialClosed.isEmpty {
                            Section("Closed") {
                                ForEach(vm.residentialClosed) { row in
                                    NavigationLink(destination: DiningDetailView(row: row)) {
                                        HallRow(row: row)
                                    }
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
                if vm.isLoading && vm.retailOpen.isEmpty && vm.retailClosed.isEmpty {
                    ProgressView("Loading…").padding()
                } else if let err = vm.errorMessage, vm.retailOpen.isEmpty && vm.retailClosed.isEmpty {
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
                        if !vm.retailOpen.isEmpty {
                            Section("Open Now") {
                                ForEach(vm.retailOpen) { row in
                                    NavigationLink(destination: CampusDetailView(row: row)) {
                                        CampusRow(row: row)
                                    }
                                }
                            }
                        }
                        if !vm.retailClosed.isEmpty {
                            Section("Closed") {
                                ForEach(vm.retailClosed) { row in
                                    NavigationLink(destination: CampusDetailView(row: row)) {
                                        CampusRow(row: row)
                                    }
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
    
    private func timeString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "H:mm"
        return formatter.string(from: date)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline) {
                Text(row.name)
                    .appFont(.headline)
                    .lineLimit(1)
                Spacer(minLength: 12)
                
                if let nextChange = row.nextChangeAt {
                    Text(timeString(from: nextChange))
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(row.openNow ? .green : .red)
                        .monospacedDigit()
                }
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
    
    private func timeString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "H:mm"
        return formatter.string(from: date)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline) {
                Text(row.name)
                    .appFont(.headline)
                    .lineLimit(1)
                Spacer(minLength: 12)
                
                if let nextChange = row.nextChangeAt {
                    Text(timeString(from: nextChange))
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(row.openNow ? .green : .red)
                        .monospacedDigit()
                }
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

// MARK: - Preview Helpers

private class PreviewDiningViewModel: DiningViewModel {
    override func load() {
        // Simulated data for preview
        let now = Date()
        
        // Create sample windows for previews
        let breakfast = ServiceWindow(
            start: Calendar.current.date(bySettingHour: 7, minute: 0, second: 0, of: now)!,
            end: Calendar.current.date(bySettingHour: 10, minute: 0, second: 0, of: now)!,
            label: "Breakfast"
        )
        let lunch = ServiceWindow(
            start: Calendar.current.date(bySettingHour: 11, minute: 0, second: 0, of: now)!,
            end: Calendar.current.date(bySettingHour: 14, minute: 0, second: 0, of: now)!,
            label: "Lunch"
        )
        let dinner = ServiceWindow(
            start: Calendar.current.date(bySettingHour: 17, minute: 0, second: 0, of: now)!,
            end: Calendar.current.date(bySettingHour: 20, minute: 0, second: 0, of: now)!,
            label: "Dinner"
        )
        
        let retailWindow = ServiceWindow(
            start: Calendar.current.date(bySettingHour: 7, minute: 0, second: 0, of: now)!,
            end: Calendar.current.date(bySettingHour: 22, minute: 0, second: 0, of: now)!
        )
        
        let residentialWindows = DayWindows(date: now, intervals: [breakfast, lunch, dinner])
        let retailWindows = DayWindows(date: now, intervals: [retailWindow])
        
        self.residentialOpen = [
            RowModel(
                id: "BruinPlate",
                name: "Bruin Plate",
                hall: DiningHall(id: "BruinPlate", name: "Bruin Plate", url: nil, type: .residential, coordinate: nil),
                openNow: true,
                currentMeal: "Dinner",
                nextChangeAt: Date().addingTimeInterval(3600),
                nextChangeType: .close,
                distanceMiles: 0.2,
                occupancy: WaitzPrediction(percentage: 75, busyness: "busy"),
                todayWindows: residentialWindows
            )
        ]
        self.residentialClosed = [
            RowModel(
                id: "DeNeveDining",
                name: "De Neve Dining",
                hall: DiningHall(id: "DeNeveDining", name: "De Neve Dining", url: nil, type: .residential, coordinate: nil),
                openNow: false,
                currentMeal: nil,
                nextChangeAt: Date().addingTimeInterval(7200),
                nextChangeType: .open,
                distanceMiles: 0.3,
                occupancy: nil,
                todayWindows: residentialWindows
            )
        ]
        self.retailOpen = [
            RowModel(
                id: "CORE",
                name: "CORE (Ready-to-Eat)",
                hall: DiningHall(id: "CORE", name: "CORE (Ready-to-Eat)", url: nil, type: .campusRetail, coordinate: nil),
                openNow: true,
                currentMeal: nil,
                nextChangeAt: Date().addingTimeInterval(14400),
                nextChangeType: .close,
                distanceMiles: 0.1,
                occupancy: nil,
                todayWindows: retailWindows
            )
        ]
        self.retailClosed = [
            RowModel(
                id: "PandaExpress",
                name: "Panda Express",
                hall: DiningHall(id: "PandaExpress", name: "Panda Express", url: nil, type: .campusRetail, coordinate: nil),
                openNow: false,
                currentMeal: nil,
                nextChangeAt: Date().addingTimeInterval(3600),
                nextChangeType: .open,
                distanceMiles: 0.15,
                occupancy: nil,
                todayWindows: retailWindows
            )
        ]
    }
}

struct DiningListView_Previews: PreviewProvider {
    static var previews: some View {
        DiningListView(vm: PreviewDiningViewModel(), mode: .halls)
    }
}
