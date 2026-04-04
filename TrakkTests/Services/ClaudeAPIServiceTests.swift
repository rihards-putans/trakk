import XCTest
@testable import Trakk

final class ClaudeAPIServiceTests: XCTestCase {

    func testParseFoodResponseJSON() throws {
        let json = """
        [{"name": "Banana (large)", "grams": 150, "calories": 135, "protein": 1.5},
         {"name": "Biezpiens (cottage cheese)", "grams": 200, "calories": 206, "protein": 36}]
        """
        let items = ClaudeAPIService.parseFoodItems(from: json)
        XCTAssertEqual(items.count, 2)
        XCTAssertEqual(items[0].name, "Banana (large)")
        XCTAssertEqual(items[0].calories, 135)
        XCTAssertEqual(items[1].protein, 36)
    }

    func testParseFoodResponseEmbeddedJSON() throws {
        let response = """
        Here are the items:
        ```json
        [{"name": "Protein shake", "grams": 300, "calories": 130, "protein": 28}]
        ```
        """
        let items = ClaudeAPIService.parseFoodItems(from: response)
        XCTAssertEqual(items.count, 1)
        XCTAssertEqual(items[0].name, "Protein shake")
    }

    func testParseFoodResponseNoJSON() throws {
        let response = "I'm not sure what that food is. Could you describe it more?"
        let items = ClaudeAPIService.parseFoodItems(from: response)
        XCTAssertTrue(items.isEmpty)
    }

    func testBuildSystemPrompt() throws {
        let prompt = ClaudeAPIService.buildSystemPrompt(
            height: 184, age: 23, sex: "male",
            goalWeight: 71, activityLevel: "moderate",
            calorieTarget: 2200, proteinTarget: 150,
            todayFoodLog: [("Protein shake", 130.0, 28.0)],
            currentWeight: 78.9,
            activeCalories: 500, restingCalories: 1900,
            steps: 8000, streak: 2
        )
        XCTAssertTrue(prompt.contains("184"))
        XCTAssertTrue(prompt.contains("Protein shake"))
        XCTAssertTrue(prompt.contains("78.9"))
        XCTAssertTrue(prompt.contains("Trakk"))
    }
}
