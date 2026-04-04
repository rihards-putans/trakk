import CoreData
import Foundation

@objc(FoodEntry)
public class FoodEntry: NSManagedObject {
    @NSManaged public var id: UUID?
    @NSManaged public var timestamp: Date?
    @NSManaged public var name: String?
    @NSManaged public var calories: Double
    @NSManaged public var protein: Double
    @NSManaged public var carbs: Double
    @NSManaged public var fat: Double
    @NSManaged public var source: String?
    @NSManaged public var barcode: String?
    @NSManaged public var claudeRaw: String?
}
