import SwiftUI

@MainActor
final class ChatViewModel: ObservableObject {
    @Published var messages: [ChatMessage] = []
    @Published var inputText: String = ""
    @Published var isLoading = false
    @Published var pendingFoodItems: [ParsedFoodItem] = []

    private let coreData = CoreDataService.shared
    private let claude = ClaudeAPIService.shared
    private let healthKit = HealthKitService.shared

    func loadHistory() {
        messages = coreData.fetchRecentChatMessages(limit: 50)
    }

    func sendMessage() async {
        let text = inputText.trimmingCharacters(in: .whitespaces)
        guard !text.isEmpty else { return }
        inputText = ""

        let userMsg = coreData.createChatMessage(role: "user", content: text)
        messages.append(userMsg)

        isLoading = true
        do {
            let systemPrompt = buildSystemPrompt()
            let response = try await claude.sendMessage(userContent: text, systemPrompt: systemPrompt)

            // Check if response contains food items
            let items = ClaudeAPIService.parseFoodItems(from: response)
            if !items.isEmpty {
                pendingFoodItems = items
                let summary = items.map { "\($0.name): \(Int($0.calories)) kcal" }.joined(separator: ", ")
                let assistantMsg = coreData.createChatMessage(role: "assistant", content: "Parsed: \(summary). Confirm to log?")
                messages.append(assistantMsg)
            } else {
                let assistantMsg = coreData.createChatMessage(role: "assistant", content: response)
                messages.append(assistantMsg)
            }
        } catch {
            let errMsg = coreData.createChatMessage(role: "assistant", content: "Something went wrong. Please try again.")
            messages.append(errMsg)
        }
        isLoading = false
    }

    func logPendingFood() {
        for item in pendingFoodItems {
            coreData.createFoodEntry(
                name: item.name,
                calories: item.calories,
                protein: item.protein,
                carbs: item.carbs,
                fat: item.fat,
                source: "text",
                claudeRaw: try? String(data: JSONEncoder().encode(item), encoding: .utf8)
            )
        }
        let confirmMsg = coreData.createChatMessage(role: "assistant", content: "Logged \(pendingFoodItems.count) item(s) ✓")
        messages.append(confirmMsg)
        pendingFoodItems = []
    }

    func dismissPendingFood() {
        pendingFoodItems = []
        let msg = coreData.createChatMessage(role: "assistant", content: "Cancelled — nothing logged.")
        messages.append(msg)
    }

    private func buildSystemPrompt() -> String {
        let profile = coreData.getOrCreateUserProfile()
        let entries = coreData.fetchTodayFoodEntries()
        let foodLog = entries.map { (name: $0.name ?? "", calories: $0.calories, protein: $0.protein) }

        return ClaudeAPIService.buildSystemPrompt(
            height: profile.height, age: Int(profile.age), sex: profile.sex ?? "male",
            goalWeight: profile.goalWeight, activityLevel: profile.activityLevel ?? "moderate",
            calorieTarget: profile.computedCalorieTarget, proteinTarget: profile.computedProteinTarget,
            todayFoodLog: foodLog,
            currentWeight: healthKit.latestWeight,
            activeCalories: healthKit.todayActiveCalories,
            restingCalories: healthKit.todayRestingCalories,
            steps: healthKit.todaySteps, streak: 0
        )
    }
}
