import SwiftUI

struct FoodEntryRow: View {
    let entry: FoodEntry

    private var timeString: String {
        guard let ts = entry.timestamp else { return "" }
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: ts)
    }

    private var sourceLabel: String {
        let src = entry.source ?? "manual"
        switch src.lowercased() {
        case "barcode": return "Barcode"
        case "claude", "ai": return "AI"
        case "manual": return "Manual"
        default: return src.capitalized
        }
    }

    var body: some View {
        HStack(spacing: 12) {
            // Source indicator dot
            Circle()
                .fill(dotColor(for: entry.source ?? "manual"))
                .frame(width: 8, height: 8)

            // Name + meta
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.name ?? "Unknown")
                    .font(Theme.bodyFont)
                    .foregroundColor(Theme.textPrimary)
                    .lineLimit(1)

                HStack(spacing: 4) {
                    Text(timeString)
                        .font(Theme.captionFont)
                        .foregroundColor(Theme.textMuted)
                    Text("·")
                        .font(Theme.captionFont)
                        .foregroundColor(Theme.textMuted)
                    Text(sourceLabel)
                        .font(Theme.captionFont)
                        .foregroundColor(Theme.textMuted)
                }
            }

            Spacer()

            // Nutrition
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(Int(entry.calories)) kcal")
                    .font(Font.system(size: 13, weight: .semibold))
                    .foregroundColor(Theme.textPrimary)

                if entry.protein > 0 {
                    Text("\(Int(entry.protein))g protein")
                        .font(Theme.captionFont)
                        .foregroundColor(Theme.textMuted)
                }
            }
        }
        .padding(.vertical, 4)
    }

    private func dotColor(for source: String) -> Color {
        switch source.lowercased() {
        case "barcode": return Theme.primary
        case "claude", "ai": return Theme.warning
        default: return Theme.textMuted
        }
    }
}
