import SwiftUI
import MapKit

/// Detailed card view for a dining hall
/// This view appears after tapping an entry in the list
struct DiningDetailView: View {
    @ObservedObject var row: DiningViewModel.RowModel
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
                    
                    // Occupancy if available
                    if let occupancy = row.occupancy {
                        Text("Occupancy: \(occupancy.busyness) (\(occupancy.percentage)%)")
                            .foregroundColor(.white)
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

struct MenuItemRow: View {
    let item: MenuItem
    let isLastInSection: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .firstTextBaseline) {
                Text(item.name)
                    .foregroundColor(.white)
                    .font(.body)
                    .fixedSize(horizontal: false, vertical: true)

                Spacer()

                // Dietary indicators
                HStack(spacing: 6) {
                    if item.isVegan {
                        Image(systemName: "leaf.fill")
                            .foregroundColor(.green)
                            .font(.caption)
                    } else if item.isVegetarian {
                        Image(systemName: "leaf")
                            .foregroundColor(.green)
                            .font(.caption)
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 12)
            
            // Only show separator if not the last item in section
            if !isLastInSection {
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(height: 0.5)
                    .padding(.horizontal, 12)
            }
        }
    }
}

#Preview {
    NavigationStack {
        DiningDetailView(row: DiningViewModel.RowModel(
            id: "BruinPlate",
            name: "Bruin Plate",
            hall: DiningHall(id: "BruinPlate", name: "Bruin Plate", url: nil, type: .residential, coordinate: GeoPoint(lat: 34.0720, lon: -118.4521)),
            distanceMiles: 0.2,
            occupancy: WaitzPrediction(percentage: 75, busyness: "busy")
        ))
    }
}
