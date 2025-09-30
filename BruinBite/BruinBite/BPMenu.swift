import Foundation

struct MenuItem: Identifiable {
    let id: String
    let name: String
    let station: String
    let isVegetarian: Bool
    let isVegan: Bool
}

struct MenuSection: Identifiable {
    let id: String
    let name: String
    let items: [MenuItem]
}

struct MealPeriod: Identifiable, Equatable {
    let id: String
    let name: String
    let sections: [MenuSection]
    
    static func == (lhs: MealPeriod, rhs: MealPeriod) -> Bool {
        return lhs.id == rhs.id
    }
}

enum MealTime: String, CaseIterable {
    case breakfast = "Breakfast"
    case lunch = "Lunch"
    case dinner = "Dinner"
}