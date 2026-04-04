import CoreData
import Foundation

@objc(ChatMessage)
public class ChatMessage: NSManagedObject {
    @NSManaged public var id: UUID?
    @NSManaged public var timestamp: Date?
    @NSManaged public var role: String?
    @NSManaged public var content: String?
    @NSManaged public var linkedFoodEntry: FoodEntry?
}
