import SwiftUI

struct NotificationSetupView: View {
    @ObservedObject var vm: OnboardingViewModel
    @Binding var isOnboardingComplete: Bool

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Notifications")
                    .font(Theme.titleFont)
                    .foregroundColor(Theme.textPrimary)

                Text("Choose what Trakk should nudge you about.")
                    .font(Theme.bodyFont)
                    .foregroundColor(Theme.textMuted)

                notifToggle("Morning summary", isOn: $vm.morningEnabled, icon: "sun.max")
                if vm.morningEnabled {
                    DatePicker("Time", selection: $vm.morningTime, displayedComponents: .hourAndMinute)
                        .foregroundColor(Theme.textMuted)
                        .padding(.leading, 36)
                }

                notifToggle("Evening nudge (if under target)", isOn: $vm.eveningNudgeEnabled, icon: "moon")
                if vm.eveningNudgeEnabled {
                    DatePicker("Time", selection: $vm.eveningNudgeTime, displayedComponents: .hourAndMinute)
                        .foregroundColor(Theme.textMuted)
                        .padding(.leading, 36)
                }

                notifToggle("Protein warning", isOn: $vm.proteinWarningEnabled, icon: "fork.knife")
                notifToggle("Weekly report", isOn: $vm.weeklyReportEnabled, icon: "chart.bar")
                notifToggle("Weigh-in reminder (Fridays)", isOn: $vm.weighInReminderEnabled, icon: "scalemass")
                notifToggle("Gym reminder", isOn: $vm.gymReminderEnabled, icon: "dumbbell")

                if vm.gymReminderEnabled {
                    HStack {
                        Text("Every")
                            .foregroundColor(Theme.textMuted)
                        Picker("", selection: $vm.gymIntervalDays) {
                            ForEach(1...7, id: \.self) { Text("\($0) days").tag($0) }
                        }
                        .pickerStyle(.menu)
                        .tint(Theme.primary)
                    }
                    .padding(.leading, 36)
                }

                Button(action: {
                    vm.completeOnboarding()
                    isOnboardingComplete = true
                }) {
                    Text("Get Started")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Theme.primary)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                        .font(.headline)
                }
                .padding(.top, 8)
            }
            .padding(Theme.screenPadding)
        }
    }

    private func notifToggle(_ label: String, isOn: Binding<Bool>, icon: String) -> some View {
        Toggle(isOn: isOn) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .foregroundColor(Theme.primary)
                    .frame(width: 24)
                Text(label)
                    .foregroundColor(Theme.textPrimary)
            }
        }
        .tint(Theme.primary)
    }
}
