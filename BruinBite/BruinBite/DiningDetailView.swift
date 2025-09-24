import SwiftUI
import MapKit

struct DiningDetailView: View {
    let row: DiningViewModel.RowModel
    @Environment(\.dismiss) private var dismiss
    
    private func timeString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "H:mm"
        return formatter.string(from: date)
    }
    
    private func formatMealWindow(_ window: ServiceWindow) -> String {
        let label = window.label ?? "Service"
        return "\(label): \(timeString(from: window.start)) - \(timeString(from: window.end))"
    }
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Back button
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "chevron.left")
                            .foregroundColor(.white)
                            .font(.system(size: 24))
                            .padding()
                    }
                    Spacer()
                }
                
                // Main Content - all content pushed to top
                VStack(spacing: 12) {
                    Text(row.name)
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                    
                    if let distance = row.distanceMiles {
                        Text(String(format: "%.2f mi", distance))
                            .font(.system(size: 20))
                            .foregroundColor(.gray)
                            .monospacedDigit()
                    }
                    
                    VStack(spacing: 8) {
                        ForEach(row.todayWindows?.intervals.sorted(by: { $0.start < $1.start }) ?? [], id: \.start) { window in
                            Text(formatMealWindow(window))
                                .font(.system(size: 25, weight: .bold))
                                .foregroundColor(window.label == row.currentMeal ? .green : .red)
                                .monospacedDigit()
                        }
                    }
                }
                .padding(.top, -20)
                
                Spacer()
                
                // Navigate Button
                Button(action: {
                    if let coord = row.hall.coordinate {
                        let mapItem = MKMapItem(placemark: MKPlacemark(coordinate: CLLocationCoordinate2D(latitude: coord.lat, longitude: coord.lon)))
                        mapItem.name = row.name
                        mapItem.openInMaps(launchOptions: [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving])
                    }
                }) {
                    Text("Navigate")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(Color.blue)
                        )
                        .padding(.horizontal)
                }
                .padding(.bottom, 40)
            }
        }
        .navigationBarHidden(true)
    }
}

#Preview {
    NavigationStack {
        let now = Date()
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
        
        let residentialWindows = DayWindows(date: now, intervals: [breakfast, lunch, dinner])
        
        DiningDetailView(row: DiningViewModel.RowModel(
            id: "BruinPlate",
            name: "Bruin Plate",
            hall: DiningHall(id: "BruinPlate", name: "Bruin Plate", url: nil, type: .residential, coordinate: GeoPoint(lat: 34.0720, lon: -118.4521)),
            openNow: true,
            currentMeal: "Dinner",
            nextChangeAt: Date().addingTimeInterval(3600),
            nextChangeType: .close,
            distanceMiles: 0.2,
            occupancy: WaitzPrediction(percentage: 75, busyness: "busy"),
            todayWindows: residentialWindows
        ))
    }
}
