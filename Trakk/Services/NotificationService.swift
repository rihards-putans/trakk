import Foundation
import UserNotifications
import BackgroundTasks

final class NotificationService: ObservableObject, @unchecked Sendable {
    static let shared = NotificationService()
    static let bgTaskID = "com.trakk.app.refresh"

    func requestPermission() async -> Bool {
        do {
            return try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .badge, .sound])
        } catch {
            return false
        }
    }

    @MainActor
    func scheduleAll(prefs: NotificationPreferences, coreData: CoreDataService) {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()

        if prefs.morningEnabled, let time = prefs.morningTime {
            scheduleDailyNotification(id: "morning", time: time, title: "Good morning", body: "Check your dashboard for today's plan.")
        }
        if prefs.eveningNudgeEnabled, let time = prefs.eveningNudgeTime {
            scheduleDailyNotification(id: "evening-nudge", time: time, title: "How's today going?", body: "Open Trakk to check your progress.")
        }
        if prefs.weighInReminderEnabled {
            scheduleWeeklyNotification(id: "weigh-in", weekday: 6, hour: 8, minute: 0, title: "Weigh-in day", body: "Step on the scale and check your trend.")
        }
        if prefs.weeklyReportEnabled {
            scheduleWeeklyNotification(id: "weekly-report", weekday: 1, hour: 19, minute: 0, title: "Weekly report ready", body: "Open Trakk to see your week in review.")
        }

        registerBackgroundRefresh()
    }

    func registerBackgroundRefresh() {
        BGTaskScheduler.shared.register(forTaskWithIdentifier: Self.bgTaskID, using: nil) { task in
            guard let refreshTask = task as? BGAppRefreshTask else {
                task.setTaskCompleted(success: false)
                return
            }
            NotificationService.shared.scheduleNextBackgroundRefresh()
            // BGTask objects are safe to call from any thread per Apple docs.
            // nonisolated(unsafe) suppresses Swift 6 Sendable check for this ObjC type.
            nonisolated(unsafe) let bgTask = refreshTask
            Task { @MainActor in
                await NotificationService.shared.evaluateAndNotify()
                bgTask.setTaskCompleted(success: true)
            }
        }
        scheduleNextBackgroundRefresh()
    }

    func scheduleNextBackgroundRefresh() {
        let request = BGAppRefreshTaskRequest(identifier: Self.bgTaskID)
        request.earliestBeginDate = Date(timeIntervalSinceNow: 60 * 30)
        try? BGTaskScheduler.shared.submit(request)
    }

    @MainActor
    func evaluateAndNotify() async {
        let coreData = CoreDataService.shared
        let prefs = coreData.getOrCreateNotificationPreferences()
        let profile = coreData.getOrCreateUserProfile()

        let todayEntries = coreData.fetchTodayFoodEntries()
        let totalCalories = todayEntries.reduce(0) { $0 + $1.calories }
        let totalProtein = todayEntries.reduce(0) { $0 + $1.protein }
        let target = profile.computedCalorieTarget
        let proteinTarget = profile.computedProteinTarget

        let hour = Calendar.current.component(.hour, from: Date())

        if prefs.eveningNudgeEnabled && hour >= 18 && totalCalories < target * 0.7 {
            sendImmediate(id: "evening-nudge-bg", title: "Looks like you're under target", body: "You've logged \(Int(totalCalories)) kcal — that's only \(Int(totalCalories / target * 100))% of your target.")
        }

        if prefs.proteinWarningEnabled && hour >= 18 && totalProtein < proteinTarget * 0.6 {
            let gap = Int(proteinTarget - totalProtein)
            sendImmediate(id: "protein-warning-bg", title: "Protein check", body: "You're \(gap)g short on protein today. Consider a shake or high-protein snack.")
        }
    }

    private func scheduleDailyNotification(id: String, time: Date, title: String, body: String) {
        let components = Calendar.current.dateComponents([.hour, .minute], from: time)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }

    private func scheduleWeeklyNotification(id: String, weekday: Int, hour: Int, minute: Int, title: String, body: String) {
        var components = DateComponents()
        components.weekday = weekday
        components.hour = hour
        components.minute = minute
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }

    private func sendImmediate(id: String, title: String, body: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }
}
