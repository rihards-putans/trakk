import SwiftUI

struct CalorieRingView: View {
    let eaten: Double
    let burned: Double
    let target: Double
    let remaining: Double

    private var eatenFraction: Double {
        guard target > 0 else { return 0 }
        return min(eaten / target, 1.0)
    }

    private var burnedFraction: Double {
        guard target > 0 else { return 0 }
        return min(burned / target, 1.0)
    }

    var body: some View {
        HStack(spacing: 16) {
            // Dual ring
            ZStack {
                // Outer ring track (burned)
                Circle()
                    .stroke(Theme.primary.opacity(0.15), lineWidth: 12)
                    .frame(width: 120, height: 120)

                // Outer ring fill (burned)
                Circle()
                    .trim(from: 0, to: burnedFraction)
                    .stroke(Theme.primary, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                    .frame(width: 120, height: 120)
                    .rotationEffect(.degrees(-90))

                // Inner ring track (eaten)
                Circle()
                    .stroke(Theme.consumed.opacity(0.15), lineWidth: 10)
                    .frame(width: 90, height: 90)

                // Inner ring fill (eaten)
                Circle()
                    .trim(from: 0, to: eatenFraction)
                    .stroke(Theme.consumed, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                    .frame(width: 90, height: 90)
                    .rotationEffect(.degrees(-90))

                // Center label
                VStack(spacing: 0) {
                    Text("\(Int(max(0, remaining)))")
                        .font(Font.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(Theme.textPrimary)
                    Text("left")
                        .font(Theme.captionFont)
                        .foregroundColor(Theme.textMuted)
                }
            }
            .animation(.easeOut(duration: 0.6), value: eatenFraction)
            .animation(.easeOut(duration: 0.6), value: burnedFraction)

            // Right side stats
            VStack(alignment: .leading, spacing: 10) {
                // Eaten row
                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(Theme.consumed)
                            .frame(width: 8, height: 8)
                        Text("Eaten")
                            .font(Theme.captionFont)
                            .foregroundColor(Theme.textMuted)
                        Spacer()
                        Text("\(Int(eaten)) kcal")
                            .font(Font.system(size: 13, weight: .semibold))
                            .foregroundColor(Theme.textPrimary)
                    }
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 3)
                                .fill(Theme.consumed.opacity(0.2))
                                .frame(height: 4)
                            RoundedRectangle(cornerRadius: 3)
                                .fill(Theme.consumed)
                                .frame(width: geo.size.width * eatenFraction, height: 4)
                        }
                    }
                    .frame(height: 4)
                }

                // Burned row
                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(Theme.primary)
                            .frame(width: 8, height: 8)
                        Text("Burned")
                            .font(Theme.captionFont)
                            .foregroundColor(Theme.textMuted)
                        Spacer()
                        Text("\(Int(burned)) kcal")
                            .font(Font.system(size: 13, weight: .semibold))
                            .foregroundColor(Theme.textPrimary)
                    }
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 3)
                                .fill(Theme.primary.opacity(0.2))
                                .frame(height: 4)
                            RoundedRectangle(cornerRadius: 3)
                                .fill(Theme.primary)
                                .frame(width: geo.size.width * burnedFraction, height: 4)
                        }
                    }
                    .frame(height: 4)
                }

                // Target label
                HStack {
                    Text("Target: \(Int(target)) kcal")
                        .font(Theme.captionFont)
                        .foregroundColor(Theme.textMuted)
                    Spacer()
                }
            }
        }
        .padding(Theme.cardPadding)
        .background(Theme.cardSurface)
        .cornerRadius(Theme.cardRadius)
    }
}

#Preview {
    CalorieRingView(eaten: 1400, burned: 500, target: 2000, remaining: 1100)
        .padding()
        .background(Theme.background)
        .preferredColorScheme(.dark)
}
