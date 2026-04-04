import CoreData
import Foundation

@MainActor
final class CoreDataService: ObservableObject {
    static let shared = CoreDataService()

    let container: NSPersistentContainer
    var viewContext: NSManagedObjectContext { container.viewContext }

    init(inMemory: Bool = false) {
        let model = Self.createModel()
        container = NSPersistentContainer(name: "Trakk", managedObjectModel: model)
        if inMemory {
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        }
        container.loadPersistentStores { _, error in
            if let error { fatalError("Core Data load failed: \(error)") }
        }
        container.viewContext.automaticallyMergesChangesFromParent = true
    }

    private static func createModel() -> NSManagedObjectModel {
        let model = NSManagedObjectModel()

        let foodEntry = NSEntityDescription()
        foodEntry.name = "FoodEntry"
        foodEntry.managedObjectClassName = "FoodEntry"
        foodEntry.properties = [
            attribute("id", .UUIDAttributeType, defaultValue: UUID()),
            attribute("timestamp", .dateAttributeType, defaultValue: Date()),
            attribute("name", .stringAttributeType),
            attribute("calories", .doubleAttributeType, defaultValue: 0),
            attribute("protein", .doubleAttributeType, defaultValue: 0, optional: true),
            attribute("carbs", .doubleAttributeType, defaultValue: 0, optional: true),
            attribute("fat", .doubleAttributeType, defaultValue: 0, optional: true),
            attribute("source", .stringAttributeType),
            attribute("barcode", .stringAttributeType, optional: true),
            attribute("claudeRaw", .stringAttributeType, optional: true),
        ]

        let chatMessage = NSEntityDescription()
        chatMessage.name = "ChatMessage"
        chatMessage.managedObjectClassName = "ChatMessage"
        chatMessage.properties = [
            attribute("id", .UUIDAttributeType, defaultValue: UUID()),
            attribute("timestamp", .dateAttributeType, defaultValue: Date()),
            attribute("role", .stringAttributeType),
            attribute("content", .stringAttributeType),
        ]

        let linkedFood = NSRelationshipDescription()
        linkedFood.name = "linkedFoodEntry"
        linkedFood.destinationEntity = foodEntry
        linkedFood.isOptional = true
        linkedFood.maxCount = 1
        linkedFood.deleteRule = .nullifyDeleteRule
        chatMessage.properties.append(linkedFood)

        let userProfile = NSEntityDescription()
        userProfile.name = "UserProfile"
        userProfile.managedObjectClassName = "UserProfile"
        userProfile.properties = [
            attribute("height", .doubleAttributeType, defaultValue: 0),
            attribute("age", .integer32AttributeType, defaultValue: 0),
            attribute("sex", .stringAttributeType, defaultValue: "male"),
            attribute("goalWeight", .doubleAttributeType, defaultValue: 0),
            attribute("activityLevel", .stringAttributeType, defaultValue: "moderate"),
            attribute("dailyCalorieTarget", .doubleAttributeType, defaultValue: 0, optional: true),
            attribute("dailyProteinTarget", .doubleAttributeType, defaultValue: 0, optional: true),
        ]

        let notifPrefs = NSEntityDescription()
        notifPrefs.name = "NotificationPreferences"
        notifPrefs.managedObjectClassName = "NotificationPreferences"
        notifPrefs.properties = [
            attribute("morningEnabled", .booleanAttributeType, defaultValue: true),
            attribute("morningTime", .dateAttributeType, defaultValue: Calendar.current.date(from: DateComponents(hour: 7, minute: 30))!),
            attribute("eveningNudgeEnabled", .booleanAttributeType, defaultValue: true),
            attribute("eveningNudgeTime", .dateAttributeType, defaultValue: Calendar.current.date(from: DateComponents(hour: 20, minute: 0))!),
            attribute("proteinWarningEnabled", .booleanAttributeType, defaultValue: true),
            attribute("weeklyReportEnabled", .booleanAttributeType, defaultValue: true),
            attribute("weighInReminderEnabled", .booleanAttributeType, defaultValue: true),
            attribute("gymReminderEnabled", .booleanAttributeType, defaultValue: true),
            attribute("gymIntervalDays", .integer32AttributeType, defaultValue: 3),
        ]

        model.entities = [foodEntry, chatMessage, userProfile, notifPrefs]
        return model
    }

    private static func attribute(
        _ name: String,
        _ type: NSAttributeType,
        defaultValue: Any? = nil,
        optional: Bool = false
    ) -> NSAttributeDescription {
        let attr = NSAttributeDescription()
        attr.name = name
        attr.attributeType = type
        attr.isOptional = optional
        if let defaultValue { attr.defaultValue = defaultValue }
        return attr
    }

    func save() {
        guard viewContext.hasChanges else { return }
        try? viewContext.save()
    }

    @discardableResult
    func createFoodEntry(
        name: String,
        calories: Double,
        protein: Double? = nil,
        carbs: Double? = nil,
        fat: Double? = nil,
        source: String,
        barcode: String? = nil,
        claudeRaw: String? = nil
    ) -> FoodEntry {
        let entry = FoodEntry(context: viewContext)
        entry.id = UUID()
        entry.timestamp = Date()
        entry.name = name
        entry.calories = calories
        entry.protein = protein ?? 0
        entry.carbs = carbs ?? 0
        entry.fat = fat ?? 0
        entry.source = source
        entry.barcode = barcode
        entry.claudeRaw = claudeRaw
        save()
        return entry
    }

    func fetchTodayFoodEntries() -> [FoodEntry] {
        let request = NSFetchRequest<FoodEntry>(entityName: "FoodEntry")
        let startOfDay = Calendar.current.startOfDay(for: Date())
        request.predicate = NSPredicate(format: "timestamp >= %@", startOfDay as NSDate)
        request.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: true)]
        return (try? viewContext.fetch(request)) ?? []
    }

    func fetchFoodEntries(for date: Date) -> [FoodEntry] {
        let request = NSFetchRequest<FoodEntry>(entityName: "FoodEntry")
        let startOfDay = Calendar.current.startOfDay(for: date)
        let endOfDay = Calendar.current.date(byAdding: .day, value: 1, to: startOfDay)!
        request.predicate = NSPredicate(format: "timestamp >= %@ AND timestamp < %@", startOfDay as NSDate, endOfDay as NSDate)
        request.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: true)]
        return (try? viewContext.fetch(request)) ?? []
    }

    func deleteFoodEntry(_ entry: FoodEntry) {
        viewContext.delete(entry)
        save()
    }

    @discardableResult
    func createChatMessage(role: String, content: String, linkedFoodEntry: FoodEntry? = nil) -> ChatMessage {
        let msg = ChatMessage(context: viewContext)
        msg.id = UUID()
        msg.timestamp = Date()
        msg.role = role
        msg.content = content
        msg.linkedFoodEntry = linkedFoodEntry
        save()
        return msg
    }

    func fetchRecentChatMessages(limit: Int) -> [ChatMessage] {
        let request = NSFetchRequest<ChatMessage>(entityName: "ChatMessage")
        request.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: true)]
        request.fetchLimit = limit
        return (try? viewContext.fetch(request)) ?? []
    }

    func clearChatHistory() {
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "ChatMessage")
        let delete = NSBatchDeleteRequest(fetchRequest: request)
        try? viewContext.execute(delete)
        save()
    }

    func getOrCreateUserProfile() -> UserProfile {
        let request = NSFetchRequest<UserProfile>(entityName: "UserProfile")
        request.fetchLimit = 1
        if let existing = (try? viewContext.fetch(request))?.first {
            return existing
        }
        let profile = UserProfile(context: viewContext)
        save()
        return profile
    }

    func getOrCreateNotificationPreferences() -> NotificationPreferences {
        let request = NSFetchRequest<NotificationPreferences>(entityName: "NotificationPreferences")
        request.fetchLimit = 1
        if let existing = (try? viewContext.fetch(request))?.first {
            return existing
        }
        let prefs = NotificationPreferences(context: viewContext)
        save()
        return prefs
    }
}
