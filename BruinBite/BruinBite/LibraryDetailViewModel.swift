import Foundation
import SwiftUI
import Combine

@MainActor
final class LibraryDetailViewModel: ObservableObject {
    @Published private(set) var libraryServices: [String: [LibraryServiceInfo]] = [:]
    private let scraper = LibraryHoursScraper.shared
    
    private let defaultServices = [
        "Night Powell",
        "CLICC Classroom Hub",
        "Equipment Lending"
    ]
    
    func refreshHours(for libraryId: String) async {
        do {
            let schedules = try await scraper.fetchLibraryHours()
            if let schedule = schedules[libraryId] {
                var services: [LibraryServiceInfo] = []
                
                // Always add all services, with closed status as default
                for serviceName in defaultServices {
                    var serviceInfo: LibraryServiceInfo?
                    
                    switch serviceName {
                    case "Night Powell":
                        if let hours = schedule.nightHours {
                            let parts = hours.split(separator: "-").map(String.init)
                            if parts.count == 2 {
                                serviceInfo = LibraryServiceInfo(
                                    name: serviceName,
                                    hours: LibraryHours(day: "Today",
                                                      open: parts[0].trimmingCharacters(in: .whitespaces),
                                                      close: parts[1].trimmingCharacters(in: .whitespaces)),
                                    status: .open
                                )
                            }
                        }
                        
                    case "CLICC Classroom Hub":
                        if let hours = schedule.cliccHours {
                            let parts = hours.split(separator: "-").map(String.init)
                            if parts.count == 2 {
                                serviceInfo = LibraryServiceInfo(
                                    name: serviceName,
                                    hours: LibraryHours(day: "Today",
                                                      open: parts[0].trimmingCharacters(in: .whitespaces),
                                                      close: parts[1].trimmingCharacters(in: .whitespaces)),
                                    status: .open
                                )
                            }
                        }
                        
                    case "Equipment Lending":
                        if let hours = schedule.equipmentHours {
                            let parts = hours.split(separator: "-").map(String.init)
                            if parts.count == 2 {
                                serviceInfo = LibraryServiceInfo(
                                    name: serviceName,
                                    hours: LibraryHours(day: "Today",
                                                      open: parts[0].trimmingCharacters(in: .whitespaces),
                                                      close: parts[1].trimmingCharacters(in: .whitespaces)),
                                    status: .open
                                )
                            }
                        }
                        
                    default:
                        break
                    }
                    
                    // If no hours were found or hours contain "–", add as closed
                    if serviceInfo == nil ||
                       (serviceInfo?.hours?.open == "–" || serviceInfo?.hours?.close == "–") {
                        serviceInfo = LibraryServiceInfo(
                            name: serviceName,
                            status: .closed
                        )
                    }
                    
                    if let info = serviceInfo {
                        services.append(info)
                    }
                }
                
                await MainActor.run {
                    libraryServices[libraryId] = services
                }
            }
        } catch {
            print("Error refreshing library hours: \(error)")
        }
    }
}
