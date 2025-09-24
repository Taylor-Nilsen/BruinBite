import SwiftUI
import MapKit

struct LibraryDetailView: View {
    let library: LibraryLocation
    let distanceMiles: Double?
    @Environment(\.dismiss) private var dismiss
    
    private func formatHours(_ hours: LibraryHours?) -> String {
        guard let hours = hours else { return "Closed" }
        return "\(hours.open) - \(hours.close)"
    }
    
    private func todayHours() -> LibraryHours? {
        let weekday = Calendar.current.weekdaySymbols[Calendar.current.component(.weekday, from: Date()) - 1]
        return library.hours.first { $0.day == weekday }
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
                
                // Main Content
                VStack(spacing: 12) {
                    Text(library.name)
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                    
                    if let distance = distanceMiles {
                        Text(String(format: "%.2f mi", distance))
                            .font(.system(size: 20))
                            .foregroundColor(.gray)
                            .monospacedDigit()
                    }
                    
                    if let hours = todayHours() {
                        Text(formatHours(hours))
                            .font(.system(size: 37, weight: .bold))
                            .foregroundColor(isOpen(hours) ? .green : .red)
                            .monospacedDigit()
                    }
                }
                .padding(.top, -20)
                
                Spacer()
                
                // Navigate Button
                Button(action: {
                    if let coord = library.coordinate {
                        let mapItem = MKMapItem(placemark: MKPlacemark(coordinate: CLLocationCoordinate2D(latitude: coord.lat, longitude: coord.lon)))
                        mapItem.name = library.name
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
    
    private func isOpen(_ hours: LibraryHours) -> Bool {
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
}

#Preview {
    NavigationStack {
        LibraryDetailView(
            library: LibraryLocation(
                id: "powell",
                name: "Powell Library",
                hours: [
                    LibraryHours(day: "Tuesday", open: "10:00", close: "16:00")
                ],
                coordinate: GeoPoint(lat: 34.07192, lon: -118.44218)
            ),
            distanceMiles: 0.2
        )
    }
}
