import SwiftUI

@MainActor
final class WeightHistoryViewModel: ObservableObject {
    enum Period: String, CaseIterable { case week = "7d", month = "30d", quarter = "90d", all = "All" }

    @Published var selectedPeriod: Period = .month
    @Published var dataPoints: [(date: Date, kg: Double)] = []
    @Published var goalWeight: Double = 72
    @Published var ratePerWeek: Double?

    private let healthKit = HealthKitService.shared
    private let coreData = CoreDataService.shared

    func load() async {
        goalWeight = coreData.getOrCreateUserProfile().goalWeight
        let days: Int = switch selectedPeriod {
        case .week: 7
        case .month: 30
        case .quarter: 90
        case .all: 365
        }
        await healthKit.fetchWeightHistory(days: days)
        // Small delay for async HealthKit callback
        try? await Task.sleep(for: .milliseconds(500))
        dataPoints = healthKit.weightHistory

        // Calculate rate
        if dataPoints.count >= 2 {
            let first = dataPoints.first!
            let last = dataPoints.last!
            let weeks = max(1, Calendar.current.dateComponents([.day], from: first.date, to: last.date).day! / 7)
            ratePerWeek = (last.kg - first.kg) / Double(weeks)
        }
    }
}
