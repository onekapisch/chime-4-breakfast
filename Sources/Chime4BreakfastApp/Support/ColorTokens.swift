import SwiftUI

/// Dark lacquer palette with restrained AI-app accents. Surfaces stay quiet;
/// color marks state, event type, and the screen-edge glow.
enum ColorTokens {
    // Surfaces
    static let base = Color(red: 0.035, green: 0.036, blue: 0.048)
    static let baseElevated = Color(red: 0.075, green: 0.078, blue: 0.105)

    // Ink scale
    static let textPrimary = Color.white
    static let fog = Color(white: 0.74)        // secondary text / labels
    static let textMuted = Color(white: 0.54)

    // Accents
    static let coral = Color(red: 1.0, green: 0.35, blue: 0.30)
    static let magenta = Color(red: 0.95, green: 0.28, blue: 0.76)
    static let violet = Color(red: 0.53, green: 0.42, blue: 1.0)
    static let electricBlue = Color(red: 0.27, green: 0.55, blue: 1.0)
    static let success = Color(red: 0.31, green: 0.86, blue: 0.57)
    static let accent = coral
    static let accentSoft = electricBlue

    // Materials
    static let stroke = Color.white.opacity(0.08)
    static let highlight = Color.white.opacity(0.12)
    static let shadow = Color.black.opacity(0.5)
}
