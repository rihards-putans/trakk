import SwiftUI

@MainActor
final class OnboardingViewModel: ObservableObject {
    @Published var currentPage = 0
    @Published var height: Double = 175
    @Published var age: Int = 25
    @Published var sex: String = "male"
    @Published var currentWeight: Double = 78
    @Published var goalWeight: Double = 72
    @Published var activityLevel: String = "moderate"
    @Published var calorieTarget: String = ""
    @Published var proteinTarget: String = ""
    @Published var healthKitAuthorized = false
    @Published var apiKey: String = ""
    @Published var isValidatingKey = false
    @Published var keyValidationResult: Bool?
    @Published var morningEnabled = true
    @Published var morningTime = Calendar.current.date(from: DateComponents(hour: 7, minute: 30))!
    @Published var eveningNudgeEnabled = true
    @Published var eveningNudgeTime = Calendar.current.date(from: DateComponents(hour: 20, minute: 0))!
    @Published var proteinWarningEnabled = true
    @Published var weeklyReportEnabled = true
    @Published var weighInReminderEnabled = true
    @Published var gymReminderEnabled = true
    @Published var gymIntervalDays: Int = 3

    let totalPages = 4

    func requestHealthKit() async {
        healthKitAuthorized = await HealthKitService.shared.requestAuthorization()
    }

    func validateAPIKey() async {
        guard !apiKey.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        isValidatingKey = true
        keyValidationResult = nil
        let valid = await ClaudeAPIService.shared.validateAPIKey(apiKey.trimmingCharacters(in: .whitespaces))
        keyValidationResult = valid
        isValidatingKey = false
    }

    func completeOnboarding() {
        let coreData = CoreDataService.shared

        let profile = coreData.getOrCreateUserProfile()
        profile.height = height
        profile.age = Int32(age)
        profile.sex = sex
        profile.goalWeight = goalWeight
        profile.activityLevel = activityLevel
        if let cal = Double(calorieTarget), cal > 0 { profile.dailyCalorieTarget = cal }
        if let prot = Double(proteinTarget), prot > 0 { profile.dailyProteinTarget = prot }
        coreData.save()

        let trimmedKey = apiKey.trimmingCharacters(in: .whitespaces)
        if !trimmedKey.isEmpty {
            KeychainService.shared.saveAPIKey(trimmedKey)
        }

        let prefs = coreData.getOrCreateNotificationPreferences()
        prefs.morningEnabled = morningEnabled
        prefs.morningTime = morningTime
        prefs.eveningNudgeEnabled = eveningNudgeEnabled
        prefs.eveningNudgeTime = eveningNudgeTime
        prefs.proteinWarningEnabled = proteinWarningEnabled
        prefs.weeklyReportEnabled = weeklyReportEnabled
        prefs.weighInReminderEnabled = weighInReminderEnabled
        prefs.gymReminderEnabled = gymReminderEnabled
        prefs.gymIntervalDays = Int32(gymIntervalDays)
        coreData.save()

        Task {
            _ = await NotificationService.shared.requestPermission()
            NotificationService.shared.scheduleAll(prefs: prefs, coreData: coreData)
        }

        UserDefaults.standard.set(true, forKey: "onboardingComplete")
    }
}
