import SwiftUI

enum NotificationEventType: String, Codable, CaseIterable, Identifiable {
    case completion
    case attention

    var id: String { rawValue }

    var title: String {
        switch self {
        case .completion:
            "Completion"
        case .attention:
            "Attention"
        }
    }

    var symbolName: String {
        switch self {
        case .completion:
            "waveform"
        case .attention:
            "bell.badge.fill"
        }
    }

    var accentColor: Color {
        switch self {
        case .completion:
            ColorTokens.electricBlue
        case .attention:
            ColorTokens.coral
        }
    }
}
