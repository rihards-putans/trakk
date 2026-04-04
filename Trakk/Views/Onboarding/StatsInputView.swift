import SwiftUI

struct StatsInputView: View {
    @ObservedObject var vm: OnboardingViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text("Your Stats")
                    .font(Theme.titleFont)
                    .foregroundColor(Theme.textPrimary)

                Text("We'll use this to calculate your targets.")
                    .font(Theme.bodyFont)
                    .foregroundColor(Theme.textMuted)

                Group {
                    labeledStepper("Height (cm)", value: $vm.height, range: 140...220, step: 1)
                    labeledStepper("Age", value: Binding(get: { Double(vm.age) }, set: { vm.age = Int($0) }), range: 16...80, step: 1)
                    sexPicker
                    labeledStepper("Current weight (kg)", value: $vm.currentWeight, range: 40...200, step: 0.5)
                    labeledStepper("Goal weight (kg)", value: $vm.goalWeight, range: 40...200, step: 0.5)
                    activityPicker
                }

                Group {
                    Text("Optional overrides")
                        .font(Theme.captionFont)
                        .foregroundColor(Theme.textMuted)
                        .textCase(.uppercase)

                    HStack {
                        Text("Calorie target")
                            .foregroundColor(Theme.textMuted)
                        Spacer()
                        TextField("Auto", text: $vm.calorieTarget)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .foregroundColor(Theme.textPrimary)
                            .frame(width: 80)
                    }
                    HStack {
                        Text("Protein target (g)")
                            .foregroundColor(Theme.textMuted)
                        Spacer()
                        TextField("Auto", text: $vm.proteinTarget)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .foregroundColor(Theme.textPrimary)
                            .frame(width: 80)
                    }
                }

                Text("Swipe right to continue →")
                    .font(Theme.captionFont)
                    .foregroundColor(Theme.primary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.top, 8)
            }
            .padding(Theme.screenPadding)
        }
    }

    private func labeledStepper(_ label: String, value: Binding<Double>, range: ClosedRange<Double>, step: Double) -> some View {
        HStack {
            Text(label).foregroundColor(Theme.textMuted)
            Spacer()
            Text(step >= 1 ? "\(Int(value.wrappedValue))" : String(format: "%.1f", value.wrappedValue))
                .foregroundColor(Theme.textPrimary)
                .font(Theme.headingFont)
            Stepper("", value: value, in: range, step: step)
                .labelsHidden()
                .tint(Theme.primary)
        }
    }

    private var sexPicker: some View {
        HStack {
            Text("Sex").foregroundColor(Theme.textMuted)
            Spacer()
            Picker("", selection: $vm.sex) {
                Text("Male").tag("male")
                Text("Female").tag("female")
            }
            .pickerStyle(.segmented)
            .frame(width: 160)
        }
    }

    private var activityPicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Activity level").foregroundColor(Theme.textMuted)
            Picker("", selection: $vm.activityLevel) {
                Text("Sedentary").tag("sedentary")
                Text("Light").tag("light")
                Text("Moderate").tag("moderate")
                Text("Active").tag("active")
            }
            .pickerStyle(.segmented)
        }
    }
}
