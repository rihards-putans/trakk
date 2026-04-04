import XCTest
import CoreData
@testable import Trakk

@MainActor
final class CoreDataServiceTests: XCTestCase {
    var service: CoreDataService!

    override func setUp() {
        super.setUp()
        service = CoreDataService(inMemory: true)
    }

    override func tearDown() {
        service = nil
        super.tearDown()
    }

    func testCreateFoodEntry() throws {
        let entry = service.createFoodEntry(
            name: "Protein shake",
            calories: 130,
            protein: 28,
            carbs: 5,
            fat: 2,
            source: "text",
            barcode: nil,
            claudeRaw: nil
        )
        XCTAssertEqual(entry.name, "Protein shake")
        XCTAssertEqual(entry.calories, 130)
        XCTAssertEqual(entry.protein, 28)
        XCTAssertEqual(entry.source, "text")
        XCTAssertNotNil(entry.id)
        XCTAssertNotNil(entry.timestamp)
    }

    func testFetchTodayFoodEntries() throws {
        _ = service.createFoodEntry(name: "Meal 1", calories: 500, protein: 30, source: "barcode")
        _ = service.createFoodEntry(name: "Meal 2", calories: 400, protein: 25, source: "text")

        let entries = service.fetchTodayFoodEntries()
        XCTAssertEqual(entries.count, 2)
    }

    func testDeleteFoodEntry() throws {
        let entry = service.createFoodEntry(name: "To delete", calories: 100, protein: 5, source: "text")
        let id = entry.objectID

        service.deleteFoodEntry(entry)

        let context = service.viewContext
        let deleted = try? context.existingObject(with: id)
        XCTAssertTrue(deleted == nil || deleted!.isDeleted)
    }

    func testCreateAndFetchChatMessage() throws {
        _ = service.createChatMessage(role: "user", content: "had a banana")
        _ = service.createChatMessage(role: "assistant", content: "Banana — 135 kcal")

        let messages = service.fetchRecentChatMessages(limit: 20)
        XCTAssertEqual(messages.count, 2)
        XCTAssertEqual(messages.first?.role, "user")
    }

    func testUserProfileSingleton() throws {
        let profile = service.getOrCreateUserProfile()
        profile.height = 184
        profile.age = 23
        profile.sex = "male"
        profile.goalWeight = 71
        service.save()

        let fetched = service.getOrCreateUserProfile()
        XCTAssertEqual(fetched.height, 184)
        XCTAssertEqual(fetched.goalWeight, 71)
    }

    func testNotificationPreferencesSingleton() throws {
        let prefs = service.getOrCreateNotificationPreferences()
        prefs.morningEnabled = true
        prefs.gymIntervalDays = 3
        service.save()

        let fetched = service.getOrCreateNotificationPreferences()
        XCTAssertTrue(fetched.morningEnabled)
        XCTAssertEqual(fetched.gymIntervalDays, 3)
    }

    func testTodayCaloriesAndProtein() throws {
        _ = service.createFoodEntry(name: "Meal 1", calories: 500, protein: 30, source: "text")
        _ = service.createFoodEntry(name: "Meal 2", calories: 400, protein: 25, source: "barcode")

        let entries = service.fetchTodayFoodEntries()
        let totalCalories = entries.reduce(0) { $0 + $1.calories }
        let totalProtein = entries.reduce(0) { $0 + $1.protein }

        XCTAssertEqual(totalCalories, 900)
        XCTAssertEqual(totalProtein, 55)
    }
}
