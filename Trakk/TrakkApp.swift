import SwiftUI

@main
struct TrakkApp: App {
    @StateObject private var coreData = CoreDataService.shared
    @State private var isOnboardingComplete = UserDefaults.standard.bool(forKey: "onboardingComplete")

    var body: some Scene {
        WindowGroup {
            ZStack {
                Theme.background.ignoresSafeArea()

                if isOnboardingComplete {
                    Text("Dashboard coming soon")
                        .font(Theme.titleFont)
                        .foregroundColor(Theme.textPrimary)
                } else {
                    OnboardingContainerView(isOnboardingComplete: $isOnboardingComplete)
                }
            }
            .preferredColorScheme(.dark)
        }
    }
}
