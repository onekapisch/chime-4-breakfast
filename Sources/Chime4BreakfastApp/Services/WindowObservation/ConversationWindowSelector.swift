import Foundation

/// Selects the Accessibility window most likely to contain an active assistant
/// conversation. Counting text nodes alone prefers large settings panes.
struct ConversationWindowSelector: Sendable {
    func select(from windows: [[String]]) -> [String]? {
        windows
            .map { (strings: $0, score: score($0)) }
            .filter { $0.score > 0 }
            .max { $0.score < $1.score }?
            .strings
    }

    private func score(_ strings: [String]) -> Int {
        let normalized = strings.map {
            $0.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        }
        let joined = normalized.joined(separator: " ")
        let conversationLabels = normalized.filter {
            ["you", "user", "assistant", "claude", "codex", "chatgpt"].contains($0)
        }.count
        let messageCount = normalized.filter {
            $0.count >= 18 && $0.split(separator: " ").count >= 3
        }.count
        let chromeCount = normalized.filter {
            ["settings", "appearance", "preferences", "history", "projects", "new chat", "search"].contains($0)
        }.count

        var value = min(messageCount, 8) * 3
        value += conversationLabels * 18
        if joined.contains("stop generating") || joined.contains("stop response") || joined.contains("stop streaming") {
            value += 14
        }
        value -= chromeCount * 12
        return value >= 12 ? value : 0
    }
}
