import SwiftUI

@main
struct TrakkApp: App {
    var body: some Scene {
        WindowGroup {
            ZStack {
                Theme.background.ignoresSafeArea()
                Text("Trakk")
                    .font(Theme.titleFont)
                    .foregroundColor(Theme.textPrimary)
            }
        }
    }
}
