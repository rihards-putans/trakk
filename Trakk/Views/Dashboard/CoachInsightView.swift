import SwiftUI

struct CoachInsightView: View {
    let insight: String
    let isLoading: Bool
    let onReply: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header row
            HStack(spacing: 8) {
                // AI badge
                HStack(spacing: 4) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(Theme.warning)
                    Text("AI Coach")
                        .font(Font.system(size: 11, weight: .semibold))
                        .foregroundColor(Theme.warning)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Theme.warning.opacity(0.15))
                .cornerRadius(6)

                Spacer()

                Button(action: onReply) {
                    Text("Reply →")
                        .font(Font.system(size: 12, weight: .medium))
                        .foregroundColor(Theme.primary)
                }
            }

            // Insight content
            if isLoading {
                HStack(spacing: 8) {
                    ProgressView()
                        .tint(Theme.textMuted)
                        .scaleEffect(0.8)
                    Text("Getting your daily insight...")
                        .font(Theme.bodyFont)
                        .foregroundColor(Theme.textMuted)
                }
                .padding(.vertical, 4)
            } else if insight.isEmpty {
                Text("Your coach insight will appear here once your data loads.")
                    .font(Theme.bodyFont)
                    .foregroundColor(Theme.textMuted)
                    .italic()
            } else {
                Text(insight)
                    .font(Theme.bodyFont)
                    .foregroundColor(Theme.textPrimary)
                    .lineSpacing(4)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(Theme.cardPadding)
        .background(
            ZStack {
                Theme.cardSurface
                LinearGradient(
                    colors: [
                        Theme.primary.opacity(0.08),
                        Theme.warning.opacity(0.05),
                        Color.clear
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
        )
        .cornerRadius(Theme.cardRadius)
        .overlay(
            RoundedRectangle(cornerRadius: Theme.cardRadius)
                .stroke(Theme.primary.opacity(0.2), lineWidth: 1)
        )
    }
}

#Preview {
    VStack(spacing: 16) {
        CoachInsightView(
            insight: "You're doing great — 102g protein already. Hit the gym today and your deficit will land perfectly. Add one more high-protein meal before 8pm to close the gap.",
            isLoading: false,
            onReply: {}
        )

        CoachInsightView(
            insight: "",
            isLoading: true,
            onReply: {}
        )
    }
    .padding()
    .background(Theme.background)
    .preferredColorScheme(.dark)
}
