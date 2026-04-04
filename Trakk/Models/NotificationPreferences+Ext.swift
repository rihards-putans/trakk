import CoreData
import Foundation

@objc(NotificationPreferences)
public class NotificationPreferences: NSManagedObject {
    @NSManaged public var morningEnabled: Bool
    @NSManaged public var morningTime: Date?
    @NSManaged public var eveningNudgeEnabled: Bool
    @NSManaged public var eveningNudgeTime: Date?
    @NSManaged public var proteinWarningEnabled: Bool
    @NSManaged public var weeklyReportEnabled: Bool
    @NSManaged public var weighInReminderEnabled: Bool
    @NSManaged public var gymReminderEnabled: Bool
    @NSManaged public var gymIntervalDays: Int32
}
