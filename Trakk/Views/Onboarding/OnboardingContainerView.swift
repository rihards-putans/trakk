import SwiftUI

struct OnboardingContainerView: View {
    @StateObject private var vm = OnboardingViewModel()
    @Binding var isOnboardingComplete: Bool

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            TabView(selection: $vm.currentPage) {
                StatsInputView(vm: vm).tag(0)
                HealthKitPermissionView(vm: vm).tag(1)
                APIKeyInputView(vm: vm).tag(2)
                NotificationSetupView(vm: vm, isOnboardingComplete: $isOnboardingComplete).tag(3)
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            .indexViewStyle(.page(backgroundDisplayMode: .always))
        }
        .preferredColorScheme(.dark)
    }
}
