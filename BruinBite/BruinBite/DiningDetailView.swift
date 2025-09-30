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
                    }
                    
                    if let hoursData = row.diningHours {
                        VStack(spacing: 8) {
                            if let breakfast = hoursData.breakfast {
                                HStack {
                                    Text("Breakfast")
                                        .font(.system(size: 16))
                                        .foregroundColor(.white)
                                    Spacer()
                                    Text(breakfast)
                                        .font(.system(size: 16))
                                        .foregroundColor(.white)
                                }
                            }
                            if let lunch = hoursData.lunch {
                                HStack {
                                    Text("Lunch")
                                        .font(.system(size: 16))
                                        .foregroundColor(.white)
                                    Spacer()
                                    Text(lunch)
                                        .font(.system(size: 16))
                                        .foregroundColor(.white)
                                }
                            }
                            if let dinner = hoursData.dinner {
                                HStack {
                                    Text("Dinner")
                                        .font(.system(size: 16))
                                        .foregroundColor(.white)
                                    Spacer()
                                    Text(dinner)
                                        .font(.system(size: 16))
                                        .foregroundColor(.white)
                                }
                            }
                            if let lateNight = hoursData.lateNight {
                                HStack {
                                    Text("Late Night")
                                        .font(.system(size: 16))
                                        .foregroundColor(.white)
                                    Spacer()
                                    Text(lateNight)
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
    
    // #Preview {
    //     DiningDetailView(row: DiningViewModel.RowModel(
    //         id: "BruinPlate",
    //         name: "Bruin Plate",
    //         hall: DiningHall(id: "BruinPlate", name: "Bruin Plate", type: .residential, coordinate: GeoPoint(lat: 34.0720, lon: -118.4521)),
    //         distanceMiles: 0.2
    //     ))
    // }
}
