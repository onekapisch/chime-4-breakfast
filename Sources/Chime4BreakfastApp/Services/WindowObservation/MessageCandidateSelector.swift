import Foundation

struct MessageCandidateSelector {
    private let blockedPhrases = [
        "search",
        "new chat",
        "settings",
        "continue",
        "open",
        "share",
        "history",
        "projects",
        "use cmd + i to generate code",
        "command k",
        "chatgpt",
        "claude desktop",
        "codex"
    ]

    func select(from rawStrings: [String]) -> String? {
        let cleaned = rawStrings
            .map { $0.replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression).trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .reduce(into: [String]()) { result, next in
                if result.last != next {
                    result.append(next)
                }
            }

        let candidates = cleaned
            .enumerated()
            .filter { isLikelyConversationText($0.element) }

        guard !candidates.isEmpty else { return nil }

        let total = max(cleaned.count, 1)

        return candidates.max(by: { score(for: $0.element, index: $0.offset, total: total) < score(for: $1.element, index: $1.offset, total: total) })?.element
    }

    private func isLikelyConversationText(_ text: String) -> Bool {
        let lowered = text.lowercased()
        let words = lowered.split(separator: " ")

        if words.count < 3 || text.count < 18 {
            return false
        }

        if blockedPhrases.contains(where: { lowered == $0 || lowered.hasPrefix($0 + " ") }) {
            return false
        }

        return true
    }

    private func score(for text: String, index: Int, total: Int) -> Double {
        let lowered = text.lowercased()
        let words = text.split(separator: " ").count
        let recency = Double(index + 1) / Double(total)
        let punctuationBonus = lowered.contains(".") || lowered.contains("?") || lowered.contains("!") || lowered.contains(":") ? 14.0 : 0.0
        let sentenceBonus = words >= 8 ? 10.0 : Double(words)
        let lengthBonus = min(Double(text.count), 120.0) * 0.18
        let markdownBonus = lowered.contains("```") || lowered.contains("`") ? 6.0 : 0.0
        let recencyBonus = recency * 20.0

        return punctuationBonus + sentenceBonus + lengthBonus + markdownBonus + recencyBonus
    }
}
