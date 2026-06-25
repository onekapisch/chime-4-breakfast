import AppKit
import SwiftUI

extension Color {
    /// Creates a color from a `#RRGGBB` (or `RRGGBB`) hex string.
    init?(hex: String) {
        var value = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        if value.hasPrefix("#") {
            value.removeFirst()
        }

        guard value.count == 6, let rgb = Int(value, radix: 16) else {
            return nil
        }

        let red = Double((rgb >> 16) & 0xFF) / 255.0
        let green = Double((rgb >> 8) & 0xFF) / 255.0
        let blue = Double(rgb & 0xFF) / 255.0
        self = Color(.sRGB, red: red, green: green, blue: blue, opacity: 1)
    }

    /// Returns an uppercase `#RRGGBB` representation, or nil if the color cannot
    /// be expressed in sRGB.
    func hexString() -> String? {
        guard let resolved = NSColor(self).usingColorSpace(.sRGB) else {
            return nil
        }

        let red = Int((resolved.redComponent * 255).rounded())
        let green = Int((resolved.greenComponent * 255).rounded())
        let blue = Int((resolved.blueComponent * 255).rounded())
        return String(format: "#%02X%02X%02X", red, green, blue)
    }
}
