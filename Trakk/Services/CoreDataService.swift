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
        if let desc = container.persistentStoreDescriptions.first {
            desc.setOption(true as NSNumber, forKey: NSMigratePersistentStoresAutomaticallyOption)
            desc.setOption(true as NSNumber, forKey: NSInferMappingModelAutomaticallyOption)
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
            attribute("sugar", .doubleAttributeType, defaultValue: 0, optional: true),
            attribute("fiber", .doubleAttributeType, defaultValue: 0, optional: true),
            attribute("sodium", .doubleAttributeType, defaultValue: 0, optional: true),
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

        let customProduct = NSEntityDescription()
        customProduct.name = "CustomProduct"
        customProduct.managedObjectClassName = "CustomProduct"
        customProduct.properties = [
            attribute("barcode", .stringAttributeType),
            attribute("name", .stringAttributeType),
            attribute("caloriesPer100g", .doubleAttributeType, defaultValue: 0),
            attribute("proteinPer100g", .doubleAttributeType, defaultValue: 0),
            attribute("carbsPer100g", .doubleAttributeType, defaultValue: 0),
            attribute("fatPer100g", .doubleAttributeType, defaultValue: 0),
            attribute("sugarPer100g", .doubleAttributeType, defaultValue: 0),
            attribute("sodiumPer100g", .doubleAttributeType, defaultValue: 0),
            attribute("servingGrams", .doubleAttributeType, defaultValue: 100),
            attribute("createdAt", .dateAttributeType, defaultValue: Date()),
        ]

        model.entities = [foodEntry, chatMessage, userProfile, notifPrefs, customProduct]
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
        sugar: Double? = nil,
        fiber: Double? = nil,
        sodium: Double? = nil,
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
        entry.sugar = sugar ?? 0
        entry.fiber = fiber ?? 0
        entry.sodium = sodium ?? 0
        entry.source = source
        entry.barcode = barcode
        entry.claudeRaw = claudeRaw
        save()
        CoachOutcomeTracker.shared.foodLogged()
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

    /// One-time cleanup: removes duplicate food entries for today (keeps earliest of each name)
    func removeTodayDuplicates() {
        let entries = fetchTodayFoodEntries()
        var seenNames: Set<String> = []
        var deleted = 0
        for entry in entries {
            let name = (entry.name ?? "").lowercased().trimmingCharacters(in: .whitespaces)
            if seenNames.contains(name) {
                viewContext.delete(entry)
                deleted += 1
            } else {
                seenNames.insert(name)
            }
        }
        if deleted > 0 { save() }
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

    // MARK: - Custom Products (barcode cache)

    func lookupCustomProduct(barcode: String) -> CustomProduct? {
        let request = NSFetchRequest<CustomProduct>(entityName: "CustomProduct")
        request.predicate = NSPredicate(format: "barcode == %@", barcode)
        request.fetchLimit = 1
        return (try? viewContext.fetch(request))?.first
    }

    @discardableResult
    func saveCustomProduct(
        barcode: String,
        name: String,
        caloriesPer100g: Double,
        proteinPer100g: Double,
        carbsPer100g: Double,
        fatPer100g: Double,
        sugarPer100g: Double,
        sodiumPer100g: Double,
        servingGrams: Double
    ) -> CustomProduct {
        // Update existing or create new
        let product = lookupCustomProduct(barcode: barcode) ?? CustomProduct(context: viewContext)
        product.barcode = barcode
        product.name = name
        product.caloriesPer100g = caloriesPer100g
        product.proteinPer100g = proteinPer100g
        product.carbsPer100g = carbsPer100g
        product.fatPer100g = fatPer100g
        product.sugarPer100g = sugarPer100g
        product.sodiumPer100g = sodiumPer100g
        product.servingGrams = servingGrams
        product.createdAt = Date()
        save()
        return product
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
