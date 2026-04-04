import SwiftUI

struct ProductResultView: View {
    let product: OFFProduct
    var onLog: () -> Void
    var onRescan: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Spacer()

            if let url = product.imageURL {
                AsyncImage(url: url) { image in
                    image.resizable().aspectRatio(contentMode: .fit)
                } placeholder: { ProgressView() }
                .frame(height: 120)
                .cornerRadius(12)
            }

            Text(product.name)
                .font(Theme.headingFont)
                .foregroundColor(Theme.textPrimary)
                .multilineTextAlignment(.center)

            if let serving = product.servingSize {
                Text("Serving: \(serving)")
                    .font(Theme.captionFont)
                    .foregroundColor(Theme.textMuted)
            }

            // Nutrients
            VStack(spacing: 8) {
                nutrientRow("Calories", value: product.caloriesPerServing ?? product.caloriesPer100g, unit: "kcal", color: Theme.consumed)
                nutrientRow("Protein", value: product.proteinPerServing ?? product.proteinPer100g, unit: "g", color: Theme.warning)
                nutrientRow("Carbs", value: product.carbsPer100g, unit: "g/100g", color: Theme.textMuted)
                nutrientRow("Fat", value: product.fatPer100g, unit: "g/100g", color: Theme.textMuted)
            }
            .padding()
            .background(Theme.cardSurface)
            .cornerRadius(Theme.cardRadius)

            HStack(spacing: 12) {
                Button("Log") { onLog() }
                    .frame(maxWidth: .infinity).padding(14)
                    .background(Theme.primary).foregroundColor(.white).cornerRadius(12)
                    .font(.headline)
                Button("Rescan") { onRescan() }
                    .frame(maxWidth: .infinity).padding(14)
                    .background(Theme.cardSurface).foregroundColor(Theme.textMuted).cornerRadius(12)
            }

            Spacer()
        }
        .padding(32)
    }

    private func nutrientRow(_ label: String, value: Double, unit: String, color: Color) -> some View {
        HStack {
            Text(label).foregroundColor(Theme.textMuted)
            Spacer()
            Text("\(Int(value)) \(unit)").foregroundColor(color).font(.system(size: 14, weight: .semibold))
        }
    }
}
