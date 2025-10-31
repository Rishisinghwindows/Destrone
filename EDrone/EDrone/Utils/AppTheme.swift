import SwiftUI

enum AppTheme {
    static let background = Color(red: 0.05, green: 0.16, blue: 0.09)
    static let surface = Color(red: 0.11, green: 0.33, blue: 0.18)
    static let elevatedSurface = Color(red: 0.15, green: 0.40, blue: 0.21)
    static let accent = Color(red: 0.28, green: 0.84, blue: 0.36)
    static let accentMuted = Color(red: 0.21, green: 0.65, blue: 0.27)
    static let textPrimary = Color.white
    static let subtle = Color.white.opacity(0.65)
    static let textInverted = Color.black
    static let stroke = Color.white.opacity(0.08)
    static let overlay = Color.black.opacity(0.4)
    static let success = Color(red: 0.22, green: 0.78, blue: 0.36)
    static let warning = Color.orange
    static let cornerRadius: CGFloat = 10
    static let fontName = "Nunito Sans"

    static func font(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        Font.custom(fontName, size: size).weight(weight)
    }
}
