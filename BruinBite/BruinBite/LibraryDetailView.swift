import SwiftUI
import MapKit

struct LibraryDetailView: View {
    let library: LibraryLocation
    let distanceMiles: Double?
    @Environment(\.dismiss) private var dismiss
    
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
                    
                    if !library.services.isEmpty {
                        VStack(spacing: 8) {
                            ForEach(library.services.sorted { $0.name == "Library" && $1.name != "Library" }, id: \.name) { service in
                                HStack {
                                    Text(service.name)
                                        .font(.system(size: 16))
                                        .foregroundColor(.white)
                                    Spacer()
                                    Text(service.time)
                                        .font(.system(size: 16))
                                        .foregroundColor(.white)
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 8)
                    } else {
                        Text("Loading hours...")
                            .font(.system(size: 16))
                            .foregroundColor(.gray)
                            .padding(.horizontal, 20)
                            .padding(.top, 8)
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
                    HStack(spacing: 8) {
                        Image(systemName: "location.fill")
                            .font(.system(size: 18, weight: .semibold))
                        Text("Navigate")
                            .appFont(.title3)
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .padding(.horizontal, 24)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.blue)
                            .shadow(color: Color.blue.opacity(0.3), radius: 8, x: 0, y: 4)
                    )
                    .padding(.horizontal, 24)
                }
                .padding(.bottom, 40)
            }
        }
        .navigationBarHidden(true)
    }
}

#Preview {
    NavigationStack {
        LibraryDetailView(
            library: LibraryLocation(
                id: "powell",
                name: "Powell Library",
                services: [],
                coordinate: GeoPoint(lat: 34.07192, lon: -118.44218)
            ),
            distanceMiles: 0.2
        )
    }
}
