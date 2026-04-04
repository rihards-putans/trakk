import SwiftUI

@MainActor
final class BarcodeScannerViewModel: ObservableObject {
    enum State { case scanning, loading, found(OFFProduct), notFound, error(String) }

    @Published var state: State = .scanning
    @Published var manualName: String = ""
    @Published var manualCalories: String = ""

    private let offService = OpenFoodFactsService.shared
    private let coreData = CoreDataService.shared

    func lookupBarcode(_ barcode: String) async {
        state = .loading
        do {
            if let product = try await offService.lookupBarcode(barcode) {
                state = .found(product)
            } else {
                state = .notFound
            }
        } catch {
            state = .error("Network error — check connection")
        }
    }

    func logProduct(_ product: OFFProduct) {
        let calories = product.caloriesPerServing ?? product.caloriesPer100g
        let protein = product.proteinPerServing ?? product.proteinPer100g
        coreData.createFoodEntry(
            name: product.name,
            calories: calories,
            protein: protein,
            carbs: product.carbsPer100g,
            fat: product.fatPer100g,
            source: "barcode"
        )
    }

    func logManualEntry() {
        guard !manualName.isEmpty, let cal = Double(manualCalories), cal > 0 else { return }
        coreData.createFoodEntry(name: manualName, calories: cal, source: "text")
    }

    func reset() {
        state = .scanning
        manualName = ""
        manualCalories = ""
    }
}
