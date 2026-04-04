import Foundation

struct OFFProduct {
    let name: String
    let caloriesPer100g: Double
    let proteinPer100g: Double
    let carbsPer100g: Double
    let fatPer100g: Double
    let caloriesPerServing: Double?
    let proteinPerServing: Double?
    let servingSize: String?
    let imageURL: URL?
}

final class OpenFoodFactsService: Sendable {
    static let shared = OpenFoodFactsService()

    private let baseURL = "https://world.openfoodfacts.org/api/v2/product/"

    func lookupBarcode(_ barcode: String) async throws -> OFFProduct? {
        let url = URL(string: "\(baseURL)\(barcode).json")!
        var request = URLRequest(url: url)
        request.setValue("Trakk iOS App - personal use", forHTTPHeaderField: "User-Agent")

        let (data, _) = try await URLSession.shared.data(for: request)
        return try Self.parseProduct(from: data)
    }

    static func parseProduct(from data: Data) throws -> OFFProduct? {
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let status = json["status"] as? Int, status == 1,
              let product = json["product"] as? [String: Any] else {
            return nil
        }

        let nutriments = product["nutriments"] as? [String: Any] ?? [:]

        return OFFProduct(
            name: product["product_name"] as? String ?? "Unknown product",
            caloriesPer100g: (nutriments["energy-kcal_100g"] as? Double) ?? 0,
            proteinPer100g: (nutriments["proteins_100g"] as? Double) ?? 0,
            carbsPer100g: (nutriments["carbohydrates_100g"] as? Double) ?? 0,
            fatPer100g: (nutriments["fat_100g"] as? Double) ?? 0,
            caloriesPerServing: nutriments["energy-kcal_serving"] as? Double,
            proteinPerServing: nutriments["proteins_serving"] as? Double,
            servingSize: product["serving_size"] as? String,
            imageURL: (product["image_url"] as? String).flatMap { URL(string: $0) }
        )
    }
}
