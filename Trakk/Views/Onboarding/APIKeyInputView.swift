import SwiftUI

struct APIKeyInputView: View {
    @ObservedObject var vm: OnboardingViewModel

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "brain.head.profile")
                .font(.system(size: 60))
                .foregroundColor(Theme.primary)

            Text("Claude AI Coach")
                .font(Theme.titleFont)
                .foregroundColor(Theme.textPrimary)

            Text("Trakk uses Claude AI for food logging and personalised coaching. Get your API key at console.anthropic.com")
                .font(Theme.bodyFont)
                .foregroundColor(Theme.textMuted)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            VStack(spacing: 12) {
                SecureField("sk-ant-...", text: $vm.apiKey)
                    .textFieldStyle(.plain)
                    .padding()
                    .background(Theme.cardSurface)
                    .cornerRadius(12)
                    .foregroundColor(Theme.textPrimary)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)

                HStack(spacing: 12) {
                    Button(action: {
                        Task { await vm.validateAPIKey() }
                    }) {
                        HStack {
                            if vm.isValidatingKey {
                                ProgressView().tint(.white)
                            } else {
                                Text("Validate")
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Theme.primary)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    .disabled(vm.apiKey.isEmpty || vm.isValidatingKey)

                    Button("Skip") {
                        vm.currentPage = 3
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Theme.cardSurface)
                    .foregroundColor(Theme.textMuted)
                    .cornerRadius(12)
                }

                if let result = vm.keyValidationResult {
                    HStack {
                        Image(systemName: result ? "checkmark.circle.fill" : "xmark.circle.fill")
                        Text(result ? "Key is valid" : "Invalid key — check and try again")
                    }
                    .foregroundColor(result ? Theme.positive : Theme.consumed)
                    .font(Theme.captionFont)
                }
            }
            .padding(.horizontal, 32)

            Spacer()

            Text("Swipe right to continue →")
                .font(Theme.captionFont)
                .foregroundColor(Theme.primary)
        }
        .padding(Theme.screenPadding)
    }
}
