import CoreData
import Foundation

@objc(UserProfile)
public class UserProfile: NSManagedObject {
    @NSManaged public var height: Double
    @NSManaged public var age: Int32
    @NSManaged public var sex: String?
    @NSManaged public var goalWeight: Double
    @NSManaged public var activityLevel: String?
    @NSManaged public var dailyCalorieTarget: Double
    @NSManaged public var dailyProteinTarget: Double

    var computedCalorieTarget: Double {
        if dailyCalorieTarget > 0 { return dailyCalorieTarget }
        let bmr: Double
        if sex == "male" {
            bmr = 10 * (goalWeight + height / 10) / 2 + 6.25 * height - 5 * Double(age) + 5
        } else {
            bmr = 10 * (goalWeight + height / 10) / 2 + 6.25 * height - 5 * Double(age) - 161
        }
        let multiplier: Double = switch activityLevel {
        case "sedentary": 1.2
        case "light": 1.375
        case "moderate": 1.55
        case "active": 1.725
        default: 1.375
        }
        return (bmr * multiplier) - 500
    }

    var computedProteinTarget: Double {
        if dailyProteinTarget > 0 { return dailyProteinTarget }
        return goalWeight * 1.8
    }
}
