import SwiftUI

struct HealthKitPermissionView: View {
    @ObservedObject var vm: OnboardingViewModel

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "heart.text.square.fill")
                .font(.system(size: 60))
                .foregroundColor(Theme.primary)

            Text("Connect Health Data")
                .font(Theme.titleFont)
                .foregroundColor(Theme.textPrimary)

            Text("Trakk reads from Apple Health to show your weight, calories burned, steps, and workouts. We never write or share your data.")
                .font(Theme.bodyFont)
                .foregroundColor(Theme.textMuted)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            VStack(alignment: .leading, spacing: 8) {
                healthItem("Weight", "scalemass")
                healthItem("Active Calories", "flame")
                healthItem("Resting Calories", "bed.double")
                healthItem("Steps", "figure.walk")
                healthItem("Workouts", "dumbbell")
            }
            .padding(.horizontal, 40)

            Button(action: {
                Task { await vm.requestHealthKit() }
            }) {
                HStack {
                    Text(vm.healthKitAuthorized ? "Connected" : "Connect HealthKit")
                    if vm.healthKitAuthorized {
                        Image(systemName: "checkmark.circle.fill")
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(vm.healthKitAuthorized ? Theme.positive : Theme.primary)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            .disabled(vm.healthKitAuthorized)
            .padding(.horizontal, 32)

            Spacer()

            Text("Swipe right to continue →")
                .font(Theme.captionFont)
                .foregroundColor(Theme.primary)
        }
        .padding(Theme.screenPadding)
    }

    private func healthItem(_ label: String, _ icon: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(Theme.primary)
                .frame(width: 24)
            Text(label)
                .foregroundColor(Theme.textPrimary)
            Spacer()
            if vm.healthKitAuthorized {
                Image(systemName: "checkmark")
                    .foregroundColor(Theme.positive)
            }
        }
    }
}
