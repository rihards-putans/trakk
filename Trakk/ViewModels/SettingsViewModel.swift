import SwiftUI

@MainActor
final class SettingsViewModel: ObservableObject {
    @Published var profile: UserProfile
    @Published var notifPrefs: NotificationPreferences
    @Published var apiKey: String
    @Published var selectedModel: String
    @Published var showExportSuccess = false

    private let coreData = CoreDataService.shared

    init() {
        profile = coreData.getOrCreateUserProfile()
        notifPrefs = coreData.getOrCreateNotificationPreferences()
        apiKey = KeychainService.shared.readAPIKey() ?? ""
        selectedModel = ClaudeAPIService.shared.selectedModel
    }

    func save() {
        coreData.save()
        if !apiKey.isEmpty {
            KeychainService.shared.saveAPIKey(apiKey)
        }
        ClaudeAPIService.shared.selectedModel = selectedModel
        NotificationService.shared.scheduleAll(prefs: notifPrefs, coreData: coreData)
    }

    func clearChatHistory() {
        coreData.clearChatHistory()
    }

    func exportCSV() -> URL? {
        let entries = coreData.fetchTodayFoodEntries() // TODO: all entries
        var csv = "Date,Name,Calories,Protein,Carbs,Fat,Source\n"
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd HH:mm"
        for e in entries {
            let date = e.timestamp.map { fmt.string(from: $0) } ?? ""
            csv += "\(date),\(e.name ?? ""),\(e.calories),\(e.protein),\(e.carbs),\(e.fat),\(e.source ?? "")\n"
        }
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("trakk-export.csv")
        try? csv.write(to: url, atomically: true, encoding: .utf8)
        return url
    }
}
