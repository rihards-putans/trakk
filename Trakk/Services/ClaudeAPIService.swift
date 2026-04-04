import Foundation

struct ParsedFoodItem: Codable, Sendable {
    let name: String
    let grams: Double?
    let calories: Double
    let protein: Double?
    let carbs: Double?
    let fat: Double?
}

final class ClaudeAPIService: ObservableObject, @unchecked Sendable {
    static let shared = ClaudeAPIService()

    @Published var selectedModel: String = "claude-haiku-4-5-20251001"

    private let baseURL = URL(string: "https://api.anthropic.com/v1/messages")!

    enum ClaudeError: Error {
        case noAPIKey, networkError(Error), invalidResponse, rateLimited
    }

    func sendMessage(userContent: String, systemPrompt: String) async throws -> String {
        guard let apiKey = KeychainService.shared.readAPIKey() else {
            throw ClaudeError.noAPIKey
        }

        var request = URLRequest(url: baseURL)
        request.httpMethod = "POST"
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        request.setValue("application/json", forHTTPHeaderField: "content-type")

        let body: [String: Any] = [
            "model": selectedModel,
            "max_tokens": 1024,
            "system": systemPrompt,
            "messages": [
                ["role": "user", "content": userContent]
            ]
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let http = response as? HTTPURLResponse else {
            throw ClaudeError.invalidResponse
        }

        if http.statusCode == 429 { throw ClaudeError.rateLimited }

        guard http.statusCode == 200 else {
            throw ClaudeError.invalidResponse
        }

        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        let content = json?["content"] as? [[String: Any]]
        let text = content?.first?["text"] as? String

        return text ?? ""
    }

    func validateAPIKey(_ key: String) async -> Bool {
        var request = URLRequest(url: baseURL)
        request.httpMethod = "POST"
        request.setValue(key, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        request.setValue("application/json", forHTTPHeaderField: "content-type")

        let body: [String: Any] = [
            "model": "claude-haiku-4-5-20251001",
            "max_tokens": 1,
            "messages": [["role": "user", "content": "hi"]]
        ]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            let status = (response as? HTTPURLResponse)?.statusCode ?? 0
            return status == 200
        } catch {
            return false
        }
    }

    func parseFoodFromText(_ text: String, systemPrompt: String) async throws -> [ParsedFoodItem] {
        let instruction = """
        The user described food they ate. Parse it into a JSON array of items.
        Return ONLY a JSON array, no other text. Each item: {"name": "...", "grams": N, "calories": N, "protein": N, "carbs": N, "fat": N}.
        Estimate values if not provided. Understand Latvian food names.
        User said: \(text)
        """
        let response = try await sendMessage(userContent: instruction, systemPrompt: systemPrompt)
        return Self.parseFoodItems(from: response)
    }

    static func parseFoodItems(from text: String) -> [ParsedFoodItem] {
        // Match a JSON array that may span multiple lines
        guard let regex = try? NSRegularExpression(pattern: "\\[.*?\\]", options: [.dotMatchesLineSeparators]) else {
            return []
        }
        let nsText = text as NSString
        guard let match = regex.firstMatch(in: text, options: [], range: NSRange(location: 0, length: nsText.length)) else {
            return []
        }
        let jsonString = nsText.substring(with: match.range)
        guard let data = jsonString.data(using: .utf8) else { return [] }
        return (try? JSONDecoder().decode([ParsedFoodItem].self, from: data)) ?? []
    }

    static func buildSystemPrompt(
        height: Double, age: Int, sex: String,
        goalWeight: Double, activityLevel: String,
        calorieTarget: Double, proteinTarget: Double,
        todayFoodLog: [(name: String, calories: Double, protein: Double)],
        currentWeight: Double?,
        activeCalories: Double, restingCalories: Double,
        steps: Double, streak: Int
    ) -> String {
        let foodLogText = todayFoodLog.isEmpty ? "No entries yet today." :
            todayFoodLog.map { "\($0.name): \(Int($0.calories)) kcal, \(Int($0.protein))g protein" }.joined(separator: "\n")
        let totalEaten = todayFoodLog.reduce(0) { $0 + $1.calories }
        let totalProtein = todayFoodLog.reduce(0) { $0 + $1.protein }
        let weightStr = currentWeight.map { String(format: "%.1f kg", $0) } ?? "unknown"

        return """
        You are Trakk, a concise weight-loss coach. Parse food entries when the user describes meals. \
        Respond in English. Understand Latvian food names and input. Keep responses under 3 sentences unless asked for detail.

        USER PROFILE:
        Height: \(Int(height))cm | Age: \(age) | Sex: \(sex) | Goal: \(Int(goalWeight))kg | Activity: \(activityLevel)
        Daily targets: \(Int(calorieTarget)) kcal, \(Int(proteinTarget))g protein

        CURRENT STATE:
        Weight: \(weightStr) | Streak: \(streak) days on track
        Today burned: \(Int(activeCalories)) active + \(Int(restingCalories)) resting = \(Int(activeCalories + restingCalories)) kcal
        Steps: \(Int(steps))

        TODAY'S FOOD LOG:
        \(foodLogText)
        Total eaten: \(Int(totalEaten)) kcal | \(Int(totalProtein))g protein | Remaining: \(Int(calorieTarget - totalEaten)) kcal
        """
    }
}
