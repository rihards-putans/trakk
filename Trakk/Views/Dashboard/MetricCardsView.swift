import SwiftUI

struct MetricCardsView: View {
    let currentWeight: Double?
    let weightHistory: [Double]
    let todayProtein: Double
    let proteinTarget: Double
    let streak: Int
    let streakDays: [Bool]
    let onWeightTap: () -> Void

    private var weightTrending: Bool {
        guard weightHistory.count >= 2 else { return false }
        let last = weightHistory.suffix(2)
        return last.first! > last.last!
    }

    private var proteinFraction: Double {
        guard proteinTarget > 0 else { return 0 }
        return min(todayProtein / proteinTarget, 1.0)
    }

    var body: some View {
        HStack(spacing: Theme.cardSpacing) {
            // Weight card
            Button(action: onWeightTap) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Weight")
                        .font(Theme.captionFont)
                        .foregroundColor(Theme.textMuted)

                    if let weight = currentWeight {
                        Text(String(format: "%.1f", weight))
                            .font(Theme.metricFont)
                            .foregroundColor(Theme.textPrimary)
                        + Text(" kg")
                            .font(Theme.captionFont)
                            .foregroundColor(Theme.textMuted)
                    } else {
                        Text("—")
                            .font(Theme.metricFont)
                            .foregroundColor(Theme.textMuted)
                    }

                    Spacer(minLength: 4)

                    SparklineView(
                        dataPoints: Array(weightHistory.suffix(14)),
                        color: weightTrending ? Theme.positive : Theme.consumed
                    )
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(Theme.cardPadding)
                .background(Theme.cardSurface)
                .cornerRadius(Theme.cardRadius)
            }
            .buttonStyle(.plain)

            // Protein card
            VStack(alignment: .leading, spacing: 6) {
                Text("Protein")
                    .font(Theme.captionFont)
                    .foregroundColor(Theme.textMuted)

                HStack(alignment: .firstTextBaseline, spacing: 2) {
                    Text("\(Int(todayProtein))")
                        .font(Theme.metricFont)
                        .foregroundColor(Theme.textPrimary)
                    Text("/\(Int(proteinTarget))g")
                        .font(Theme.captionFont)
                        .foregroundColor(Theme.textMuted)
                }

                Spacer(minLength: 4)

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(Theme.warning.opacity(0.2))
                            .frame(height: 5)
                        RoundedRectangle(cornerRadius: 3)
                            .fill(Theme.warning)
                            .frame(width: geo.size.width * proteinFraction, height: 5)
                    }
                }
                .frame(height: 5)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(Theme.cardPadding)
            .background(Theme.cardSurface)
            .cornerRadius(Theme.cardRadius)

            // Streak card
            VStack(alignment: .leading, spacing: 6) {
                Text("Streak")
                    .font(Theme.captionFont)
                    .foregroundColor(Theme.textMuted)

                HStack(alignment: .firstTextBaseline, spacing: 2) {
                    Text("\(streak)")
                        .font(Theme.metricFont)
                        .foregroundColor(Theme.textPrimary)
                    Text("days")
                        .font(Theme.captionFont)
                        .foregroundColor(Theme.textMuted)
                }

                Spacer(minLength: 4)

                // 7-day dot indicator
                HStack(spacing: 4) {
                    ForEach(0..<7, id: \.self) { i in
                        Circle()
                            .fill(i < streakDays.count && streakDays[i] ? Theme.positive : Theme.inactive)
                            .frame(width: 8, height: 8)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(Theme.cardPadding)
            .background(Theme.cardSurface)
            .cornerRadius(Theme.cardRadius)
        }
    }
}

#Preview {
    MetricCardsView(
        currentWeight: 81.2,
        weightHistory: [83.0, 82.5, 82.1, 81.8, 81.5, 81.3, 81.2],
        todayProtein: 102,
        proteinTarget: 150,
        streak: 4,
        streakDays: [true, true, true, false, true, true, true],
        onWeightTap: {}
    )
    .padding()
    .background(Theme.background)
    .preferredColorScheme(.dark)
}
