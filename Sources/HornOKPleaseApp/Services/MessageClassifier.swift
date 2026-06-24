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

    func classify(_ message: String, extraPhrases: [String] = []) -> NotificationEventType {
        let normalized = normalize(message)

        if normalized.contains("?") {
            return .attention
        }

        let phrases = attentionPhrases + extraPhrases.map { normalize($0) }.filter { !$0.isEmpty }
        if phrases.contains(where: { containsWholePhrase($0, in: normalized) }) {
            return .attention
        }

        let words = normalized.split(separator: " ")
        if words.count < 10, words.first.map(String.init) == "please" {
            return .attention
        }

        return .completion
    }

    /// Matches a phrase only on whole-word boundaries so substrings inside
    /// larger words do not trigger a false positive (for example, "approved"
    /// must not match "approve", and "unblocked" must not match "blocked").
    private func containsWholePhrase(_ phrase: String, in text: String) -> Bool {
        let pattern = "\\b" + NSRegularExpression.escapedPattern(for: phrase) + "\\b"
        return text.range(of: pattern, options: .regularExpression) != nil
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
