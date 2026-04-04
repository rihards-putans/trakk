import SwiftUI

@MainActor
final class FoodLogViewModel: ObservableObject {
    @Published var selectedDate = Date()
    @Published var entries: [FoodEntry] = []
    @Published var totalCalories: Double = 0
    @Published var totalProtein: Double = 0

    private let coreData = CoreDataService.shared

    func load() {
        entries = coreData.fetchFoodEntries(for: selectedDate)
        totalCalories = entries.reduce(0) { $0 + $1.calories }
        totalProtein = entries.reduce(0) { $0 + $1.protein }
    }

    func delete(_ entry: FoodEntry) {
        coreData.deleteFoodEntry(entry)
        load()
    }
}
