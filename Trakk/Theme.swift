import SwiftUI

enum Theme {
    // MARK: - Backgrounds
    static let background = Color(red: 0.031, green: 0.055, blue: 0.078)       // #080e14
    static let cardSurface = Color(red: 0.059, green: 0.098, blue: 0.133)      // #0f1922
    static let inactive = Color(red: 0.075, green: 0.141, blue: 0.188)         // #132430

    // MARK: - Accents
    static let primary = Color(red: 0.176, green: 0.831, blue: 0.749)          // #2dd4bf (teal)
    static let consumed = Color(red: 0.984, green: 0.443, blue: 0.522)         // #fb7185 (coral)
    static let positive = Color(red: 0.290, green: 0.871, blue: 0.502)         // #4ade80 (green)
    static let warning = Color(red: 0.984, green: 0.749, blue: 0.141)          // #fbbf24 (amber)

    // MARK: - Text
    static let textPrimary = Color(red: 0.941, green: 0.941, blue: 0.941)      // #f0f0f0
    static let textMuted = Color(red: 0.478, green: 0.604, blue: 0.667)        // #7a9aaa

    // MARK: - Typography
    static let titleFont = Font.system(size: 22, weight: .bold)
    static let headingFont = Font.system(size: 18, weight: .bold)
    static let bodyFont = Font.system(size: 14, weight: .regular)
    static let captionFont = Font.system(size: 11, weight: .regular)
    static let metricFont = Font.system(size: 22, weight: .bold, design: .rounded)

    // MARK: - Spacing
    static let cardRadius: CGFloat = 14
    static let cardPadding: CGFloat = 14
    static let screenPadding: CGFloat = 20
    static let cardSpacing: CGFloat = 10
}
