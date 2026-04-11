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
    @Published var lastWorkoutDate: Date?
    @Published var gymIntervalDays: Int = 3

    // MARK: - Services
    private let healthKit = HealthKitService.shared
    private let coreData = CoreDataService.shared
    private let claude = ClaudeAPIService.shared

    // MARK: - Refresh
    func refresh() async {
        updateGreeting()
        updateDayCount()
        loadFromCoreData()

        // HealthKit: 8s timeout so the app never hangs if healthd is stuck
        await withTaskGroup(of: Bool.self) { group in
            group.addTask {
                await self.healthKit.refreshAll()
                return true
            }
            group.addTask {
                try? await Task.sleep(for: .seconds(8))
                return false
            }
            _ = await group.next()
            group.cancelAll()
        }
        loadFromHealthKit()
        calculateStreak()
    }

    // MARK: - Coach Insight

    // Fallback used only if the bundled prompt file is missing — must stay byte-for-byte identical
    // to Resources/dashboard-coach-prompt.txt so a swap doesn't change behavior.
    private static let fallbackCoachPrompt = "You are Trakk, a concise weight-loss coach. Respond in English only. Keep responses to exactly 2 sentences. Refer to the user's goal weight directly (e.g. 'your 71kg goal'), never as a loss amount (e.g. avoid 'your 8kg goal'). HARD RULE: Never recommend eating any food (no dinner, snacks, protein, anything) between 22:00 and 05:00 — the user is winding down for sleep or already asleep."

    static let dashboardCoachPrompt: String = {
        guard let url = Bundle.main.url(forResource: "dashboard-coach-prompt", withExtension: "txt"),
              let text = try? String(contentsOf: url, encoding: .utf8) else {
            return fallbackCoachPrompt
        }
        return text.trimmingCharacters(in: .whitespacesAndNewlines)
    }()

    func loadCoachInsight() async {
        isLoadingInsight = true
        defer { isLoadingInsight = false }

        let profile = coreData.getOrCreateUserProfile()
        let userContent = buildInsightPrompt(profile: profile)
        let previousOutput = coachInsight

        do {
            let response = try await claude.sendMessage(
                userContent: userContent,
                systemPrompt: Self.dashboardCoachPrompt
            )
            let newOutput = response.trimmingCharacters(in: .whitespacesAndNewlines)
            coachInsight = newOutput

            let inputs: [String: Any] = [
                "clockTime": Self.currentClockString(),
                "workout": workoutContextString(),
                "todayEaten": todayEaten,
                "calorieTarget": calorieTarget,
                "todayProtein": todayProtein,
                "proteinTarget": proteinTarget,
                "streak": streak,
                "todayBurned": todayBurned,
                "currentWeight": currentWeight ?? 0,
                "goalWeight": profile.goalWeight,
            ]
            CoachOutcomeTracker.shared.insightRegenerated(
                previousOutput: previousOutput,
                newOutput: newOutput
            )
            let insightId = CoachInsightLog.append(
                prompt: Self.dashboardCoachPrompt,
                inputs: inputs,
                output: newOutput
            )
            CoachOutcomeTracker.shared.startTracking(insightId: insightId)
        } catch {
            coachInsight = "Keep logging your meals consistently — small habits lead to big results. Stay on track today!"
        }
    }

    private static func currentClockString() -> String {
        let now = Date()
        let cal = Calendar.current
        return String(format: "%02d:%02d", cal.component(.hour, from: now), cal.component(.minute, from: now))
    }

    private func workoutContextString() -> String {
        guard let last = lastWorkoutDate else { return "no recent workouts logged" }
        let cal = Calendar.current
        let days = cal.dateComponents([.day], from: cal.startOfDay(for: last), to: cal.startOfDay(for: Date())).day ?? 0
        switch days {
        case 0: return "trained today"
        case 1: return "trained yesterday — today is recovery"
        default: return "last workout \(days) days ago"
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
        caloriesRemaining = calorieTarget - todayEaten

        let notifPrefs = coreData.getOrCreateNotificationPreferences()
        let rawInterval = Int(notifPrefs.gymIntervalDays)
        // Lightweight Core Data migrations default new attributes to 0, not the schema's
        // declared default. Repair stale/invalid values on read so the rest of the app
        // never has to defend against them.
        if rawInterval < 1 || rawInterval > 7 {
            notifPrefs.gymIntervalDays = 3
            coreData.save()
            gymIntervalDays = 3
        } else {
            gymIntervalDays = rawInterval
        }
    }

    private func loadFromHealthKit() {
        todayBurned = healthKit.todayTotalBurned
        currentWeight = healthKit.latestWeight
        weightHistory = healthKit.weightHistory.map { $0.kg }
        lastWorkoutDate = healthKit.lastWorkoutDate
        // No need to add burned — calorieTarget already accounts for BMR
        caloriesRemaining = calorieTarget - todayEaten
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
        let now = Date()
        let hour = Calendar.current.component(.hour, from: now)
        let clockTime = String(format: "%02d:%02d", hour, Calendar.current.component(.minute, from: now))

        let timeContext: String
        let lateNightDirective: String
        switch hour {
        case 5..<12:
            timeContext = "morning — most of the day still ahead for eating"
            lateNightDirective = ""
        case 12..<15:
            timeContext = "early afternoon — roughly halfway through the day"
            lateNightDirective = ""
        case 15..<18:
            timeContext = "late afternoon — main evening meal still ahead"
            lateNightDirective = ""
        case 18..<22:
            timeContext = "evening — winding down, last meal of the day window"
            lateNightDirective = ""
        default: // 22, 23, 0, 1, 2, 3, 4
            timeContext = "late night / past midnight — the user is heading to bed soon (or already asleep)"
            lateNightDirective = """

                CRITICAL: Do NOT suggest eating anything (no dinner, snacks, protein shakes — nothing). \
                The user is going to sleep within the next ~hour. \
                If the calorie count looks low, remember the day just rolled over at midnight — that 0 kcal does not mean the user under-ate yesterday, it means today just started. \
                Focus on hydration, sleep quality, recovery, or a one-line plan for tomorrow.
                """
        }

        // Workout context — helps Claude reason about recovery vs training day.
        let workoutContext: String
        if let last = lastWorkoutDate {
            let cal = Calendar.current
            let days = cal.dateComponents([.day], from: cal.startOfDay(for: last), to: cal.startOfDay(for: now)).day ?? 0
            switch days {
            case 0: workoutContext = "trained today"
            case 1: workoutContext = "trained yesterday — today is recovery"
            default: workoutContext = "last workout \(days) days ago"
            }
        } else {
            workoutContext = "no recent workouts logged"
        }

        return """
        Give me a 2-sentence coaching tip based on my current status:
        - Current clock time: \(clockTime)
        - Time of day: \(timeContext)
        - Workout: \(workoutContext)
        - Current weight: \(weightStr)
        - Goal weight: \(Int(profile.goalWeight)) kg
        - Calories eaten today: \(Int(todayEaten)) of \(Int(calorieTarget)) target (\(remainingStr) remaining)
        - Protein: \(Int(todayProtein))g of \(Int(proteinTarget))g target
        - Streak: \(streak) days on track
        - Calories burned today (active only): \(Int(todayBurned)) kcal
        Consider the time of day — a large remaining budget in the morning is normal, not alarming.\(lateNightDirective)
        Be specific, concise, and encouraging.
        """
    }
}
