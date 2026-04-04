import CoreData
import Foundation
import SwiftUI

@MainActor
final class DashboardViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var greeting: String = "Good morning"
    @Published var dayCount: Int = 0
    @Published var todayEaten: Double = 0
    @Published var todayBurned: Double = 0
    @Published var calorieTarget: Double = 2000
    @Published var caloriesRemaining: Double = 2000
    @Published var currentWeight: Double? = nil
    @Published var weightHistory: [Double] = []
    @Published var todayProtein: Double = 0
    @Published var proteinTarget: Double = 150
    @Published var streak: Int = 0
    @Published var streakDays: [Bool] = Array(repeating: false, count: 7)
    @Published var recentFoodEntries: [FoodEntry] = []
    @Published var coachInsight: String = ""
    @Published var isLoadingInsight: Bool = false

    // MARK: - Services
    private let healthKit = HealthKitService.shared
    private let coreData = CoreDataService.shared
    private let claude = ClaudeAPIService.shared

    // MARK: - Refresh
    func refresh() async {
        updateGreeting()
        updateDayCount()
        await healthKit.refreshAll()
        loadFromCoreData()
        loadFromHealthKit()
        calculateStreak()
    }

    // MARK: - Coach Insight
    func loadCoachInsight() async {
        guard coachInsight.isEmpty else { return }
        isLoadingInsight = true
        defer { isLoadingInsight = false }

        let profile = coreData.getOrCreateUserProfile()
        let systemPrompt = "You are Trakk, a concise weight-loss coach. Respond in English only. Keep responses to exactly 2 sentences."
        let userContent = buildInsightPrompt(profile: profile)

        do {
            let response = try await claude.sendMessage(userContent: userContent, systemPrompt: systemPrompt)
            coachInsight = response.trimmingCharacters(in: .whitespacesAndNewlines)
        } catch {
            coachInsight = "Keep logging your meals consistently — small habits lead to big results. Stay on track today!"
        }
    }

    // MARK: - Private Helpers

    private func updateGreeting() {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12:
            greeting = "Good morning"
        case 12..<17:
            greeting = "Good afternoon"
        case 17..<22:
            greeting = "Good evening"
        default:
            greeting = "Good night"
        }
    }

    private func updateDayCount() {
        if let onboardingDate = UserDefaults.standard.object(forKey: "onboardingDate") as? Date {
            let days = Calendar.current.dateComponents([.day], from: onboardingDate, to: Date()).day ?? 0
            dayCount = max(0, days) + 1
        } else {
            // Store today as onboarding date if not set
            UserDefaults.standard.set(Date(), forKey: "onboardingDate")
            dayCount = 1
        }
    }

    private func loadFromCoreData() {
        let entries = coreData.fetchTodayFoodEntries()
        todayEaten = entries.reduce(0) { $0 + $1.calories }
        todayProtein = entries.reduce(0) { $0 + $1.protein }
        recentFoodEntries = Array(entries.suffix(3))

        let profile = coreData.getOrCreateUserProfile()
        calorieTarget = profile.dailyCalorieTarget > 0 ? profile.dailyCalorieTarget : 2000
        proteinTarget = profile.dailyProteinTarget > 0 ? profile.dailyProteinTarget : 150
        caloriesRemaining = calorieTarget - todayEaten + todayBurned
    }

    private func loadFromHealthKit() {
        todayBurned = healthKit.todayTotalBurned
        currentWeight = healthKit.latestWeight
        weightHistory = healthKit.weightHistory.map { $0.kg }
        // Recalculate remaining now that burned is loaded
        caloriesRemaining = calorieTarget - todayEaten + todayBurned
    }

    private func calculateStreak() {
        var days: [Bool] = []
        var consecutiveStreak = 0
        let cal = Calendar.current

        for i in 0..<7 {
            guard let date = cal.date(byAdding: .day, value: -i, to: Date()) else {
                days.append(false)
                continue
            }
            let onTrack = isOnTrack(for: date)
            days.append(onTrack)
            if i == 0 || (i > 0 && days[i - 1] == true) {
                if onTrack { consecutiveStreak += 1 }
            }
        }

        // Reverse so index 0 = 6 days ago, index 6 = today
        streakDays = days.reversed()

        // Count consecutive days from today backwards
        var count = 0
        for onTrack in days {
            if onTrack { count += 1 } else { break }
        }
        streak = count
    }

    private func isOnTrack(for date: Date) -> Bool {
        let entries = coreData.fetchFoodEntries(for: date)
        guard entries.count >= 2 else { return false }
        let totalCalories = entries.reduce(0) { $0 + $1.calories }
        let lower = calorieTarget * 0.8
        let upper = calorieTarget * 1.2
        return totalCalories >= lower && totalCalories <= upper
    }

    private func buildInsightPrompt(profile: UserProfile) -> String {
        let weightStr = currentWeight.map { String(format: "%.1f kg", $0) } ?? "unknown"
        let remainingStr = String(format: "%.0f", max(0, caloriesRemaining))
        return """
        Give me a 2-sentence coaching tip based on my current status:
        - Weight: \(weightStr), goal: \(Int(profile.goalWeight)) kg
        - Calories eaten today: \(Int(todayEaten)) of \(Int(calorieTarget)) target (\(remainingStr) remaining)
        - Protein: \(Int(todayProtein))g of \(Int(proteinTarget))g target
        - Streak: \(streak) days on track
        - Calories burned today: \(Int(todayBurned)) kcal
        Be specific, concise, and encouraging.
        """
    }
}
