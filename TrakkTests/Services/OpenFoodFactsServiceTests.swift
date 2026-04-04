import XCTest
@testable import Trakk

final class OpenFoodFactsServiceTests: XCTestCase {

    func testParseProductResponse() throws {
        let json = """
        {
            "status": 1,
            "product": {
                "product_name": "High Protein Chicken Meal",
                "nutriments": {
                    "energy-kcal_100g": 150,
                    "proteins_100g": 22,
                    "carbohydrates_100g": 10,
                    "fat_100g": 5,
                    "energy-kcal_serving": 450,
                    "proteins_serving": 66
                },
                "serving_size": "300g",
                "image_url": "https://example.com/image.jpg"
            }
        }
        """.data(using: .utf8)!

        let product = try OpenFoodFactsService.parseProduct(from: json)
        XCTAssertNotNil(product)
        XCTAssertEqual(product?.name, "High Protein Chicken Meal")
        XCTAssertEqual(product?.caloriesPer100g, 150)
        XCTAssertEqual(product?.proteinPer100g, 22)
        XCTAssertEqual(product?.caloriesPerServing, 450)
    }

    func testParseProductNotFound() throws {
        let json = """
        {"status": 0}
        """.data(using: .utf8)!

        let product = try OpenFoodFactsService.parseProduct(from: json)
        XCTAssertNil(product)
    }
}
