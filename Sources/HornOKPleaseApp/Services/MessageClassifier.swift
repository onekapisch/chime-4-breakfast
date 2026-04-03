import Foundation

struct MessageClassifier {
    private let attentionPhrases = [
        "choose",
        "which one",
        "which do you want",
        "approve",
        "confirm",
        "need your input",
        "waiting on you",
        "blocked",
        "pick one",
        "let me know"
    ]

    func classify(_ message: String) -> NotificationEventType {
        let normalized = normalize(message)

        if normalized.contains("?") {
            return .attention
        }

        if attentionPhrases.contains(where: normalized.contains) {
            return .attention
        }

        let words = normalized.split(separator: " ")
        if words.count < 10, words.first.map(String.init) == "please" {
            return .attention
        }

        return .completion
    }

    func normalizedExcerpt(from message: String, limit: Int = 96) -> String {
        let compact = message
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard compact.count > limit else { return compact }
        return String(compact.prefix(limit - 1)) + "…"
    }

    func normalize(_ message: String) -> String {
        message
            .lowercased()
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
