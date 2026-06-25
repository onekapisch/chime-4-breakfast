import Foundation

enum TargetApp: String, Codable, CaseIterable, Identifiable, Hashable {
    case codex
    case claude

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .codex:
            "Codex"
        case .claude:
            "Claude"
        }
    }

    var bundleIdentifier: String {
        switch self {
        case .codex:
            "com.openai.codex"
        case .claude:
            "com.anthropic.claudefordesktop"
        }
    }
}
