import SwiftUI

struct FoodLogPreviewView: View {
    let entries: [FoodEntry]
    let onSeeAll: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Header
            HStack {
                Text("Today's Log")
                    .font(Theme.headingFont)
                    .foregroundColor(Theme.textPrimary)

                Spacer()

                Button(action: onSeeAll) {
                    Text("See all →")
                        .font(Theme.captionFont)
                        .foregroundColor(Theme.primary)
                }
            }

            if entries.isEmpty {
                HStack {
                    Spacer()
                    VStack(spacing: 6) {
                        Text("No meals logged yet")
                            .font(Theme.bodyFont)
                            .foregroundColor(Theme.textMuted)
                        Text("Tap + to add your first meal")
                            .font(Theme.captionFont)
                            .foregroundColor(Theme.textMuted)
                    }
                    Spacer()
                }
                .padding(.vertical, 12)
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(entries.enumerated()), id: \.offset) { index, entry in
                        FoodEntryRow(entry: entry)

                        if index < entries.count - 1 {
                            Divider()
                                .background(Theme.inactive)
                        }
                    }
                }
            }
        }
        .padding(Theme.cardPadding)
        .background(Theme.cardSurface)
        .cornerRadius(Theme.cardRadius)
    }
}
