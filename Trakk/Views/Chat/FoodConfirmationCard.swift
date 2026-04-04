import SwiftUI

struct FoodConfirmationCard: View {
    let items: [ParsedFoodItem]
    var onLog: () -> Void
    var onCancel: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(items, id: \.name) { item in
                HStack {
                    Text(item.name).foregroundColor(Theme.textPrimary).font(.system(size: 13))
                    Spacer()
                    VStack(alignment: .trailing) {
                        Text("\(Int(item.calories)) kcal").foregroundColor(Theme.textPrimary).font(.system(size: 13, weight: .semibold))
                        if let protein = item.protein, protein > 0 {
                            Text("\(Int(protein))g protein").foregroundColor(Theme.warning).font(Theme.captionFont)
                        }
                    }
                }
            }

            HStack(spacing: 12) {
                Button("Log") { onLog() }
                    .frame(maxWidth: .infinity).padding(10)
                    .background(Theme.primary).foregroundColor(.white).cornerRadius(8)
                    .font(.system(size: 14, weight: .medium))
                Button("Cancel") { onCancel() }
                    .frame(maxWidth: .infinity).padding(10)
                    .background(Theme.inactive).foregroundColor(Theme.textMuted).cornerRadius(8)
                    .font(.system(size: 14, weight: .medium))
            }
        }
        .padding(12)
        .background(Theme.cardSurface)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.primary.opacity(0.3), lineWidth: 1))
        .cornerRadius(12)
    }
}
