import SwiftUI
import MapKit

struct CampusDetailView: View {
    let row: DiningViewModel.RowModel
    @Environment(\.dismiss) private var dismiss
    
    private func timeString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "H:mm"
        return formatter.string(from: date)
    }
    
    private func formatOperatingHours() -> String {
        guard let windows = row.todayWindows?.intervals else { return "Closed" }
        
        if let firstWindow = windows.min(by: { $0.start < $1.start }),
           let lastWindow = windows.max(by: { $0.end < $1.end }) {
            return "\(timeString(from: firstWindow.start)) - \(timeString(from: lastWindow.end))"
        }
        return "Closed"
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
                    
                    Text(formatOperatingHours())
                        .font(.system(size: 37, weight: .bold))
                        .foregroundColor(row.openNow ? .green : .red)
                        .monospacedDigit()
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
        let retailWindow = ServiceWindow(
            start: Calendar.current.date(bySettingHour: 7, minute: 0, second: 0, of: now)!,
            end: Calendar.current.date(bySettingHour: 22, minute: 0, second: 0, of: now)!
        )
        let retailWindows = DayWindows(date: now, intervals: [retailWindow])
        
        CampusDetailView(row: DiningViewModel.RowModel(
            id: "CORE",
            name: "CORE (Ready-to-Eat)",
            hall: DiningHall(id: "CORE", name: "CORE (Ready-to-Eat)", url: nil, type: .campusRetail, coordinate: GeoPoint(lat: 34.0720, lon: -118.4521)),
            openNow: true,
            currentMeal: nil,
            nextChangeAt: Date().addingTimeInterval(14400),
            nextChangeType: .close,
            distanceMiles: 0.1,
            occupancy: nil,
            todayWindows: retailWindows
        ))
    }
}
