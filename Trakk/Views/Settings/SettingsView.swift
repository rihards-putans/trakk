import SwiftUI

struct SettingsView: View {
    @StateObject private var vm = SettingsViewModel()
    @State private var showClearConfirm = false

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            Form {
                Section("Profile") {
                    HStack { Text("Height"); Spacer(); Text("\(Int(vm.profile.height)) cm").foregroundColor(Theme.textMuted) }
                    Stepper("Age: \(vm.profile.age)", value: Binding(get: { Int(vm.profile.age) }, set: { vm.profile.age = Int32($0) }), in: 16...80)
                    HStack {
                        Text("Goal weight")
                        Spacer()
                        Text(String(format: "%.1f kg", vm.profile.goalWeight)).foregroundColor(Theme.textMuted)
                    }
                    Picker("Activity", selection: Binding(get: { vm.profile.activityLevel ?? "moderate" }, set: { vm.profile.activityLevel = $0 })) {
                        Text("Sedentary").tag("sedentary")
                        Text("Light").tag("light")
                        Text("Moderate").tag("moderate")
                        Text("Active").tag("active")
                    }
                }

                Section("AI Coach") {
                    SecureField("API Key", text: $vm.apiKey)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                    Picker("Model", selection: $vm.selectedModel) {
                        Text("Haiku (fast, cheap)").tag("claude-haiku-4-5-20251001")
                        Text("Sonnet (smarter)").tag("claude-sonnet-4-6")
                    }
                }

                Section("Notifications") {
                    Toggle("Morning summary", isOn: $vm.notifPrefs.morningEnabled)
                    Toggle("Evening nudge", isOn: $vm.notifPrefs.eveningNudgeEnabled)
                    Toggle("Protein warning", isOn: $vm.notifPrefs.proteinWarningEnabled)
                    Toggle("Weekly report", isOn: $vm.notifPrefs.weeklyReportEnabled)
                    Toggle("Weigh-in reminder", isOn: $vm.notifPrefs.weighInReminderEnabled)
                    Toggle("Gym reminder", isOn: $vm.notifPrefs.gymReminderEnabled)
                    if vm.notifPrefs.gymReminderEnabled {
                        Stepper("Every \(vm.notifPrefs.gymIntervalDays) days",
                                value: Binding(get: { Int(vm.notifPrefs.gymIntervalDays) }, set: { vm.notifPrefs.gymIntervalDays = Int32($0) }),
                                in: 1...7)
                    }
                }

                Section("Data") {
                    if let url = vm.exportCSV() {
                        ShareLink(item: url) {
                            Label("Export food log as CSV", systemImage: "square.and.arrow.up")
                        }
                    }
                    Button("Clear chat history", role: .destructive) { showClearConfirm = true }
                }

                Section("About") {
                    HStack { Text("App"); Spacer(); Text("Trakk v1.0").foregroundColor(Theme.textMuted) }
                    HStack { Text("AI"); Spacer(); Text("Claude by Anthropic").foregroundColor(Theme.textMuted) }
                    HStack { Text("Food data"); Spacer(); Text("Open Food Facts").foregroundColor(Theme.textMuted) }
                }
            }
            .scrollContentBackground(.hidden)
            .tint(Theme.primary)
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .onDisappear { vm.save() }
        .alert("Clear chat history?", isPresented: $showClearConfirm) {
            Button("Clear", role: .destructive) { vm.clearChatHistory() }
            Button("Cancel", role: .cancel) {}
        }
    }
}
